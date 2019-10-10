defmodule NervesHub.Connection do
  @moduledoc """
  Agent used to keep the simple state of the devices connection
  to [nerves-hub.org](https://www.nerves-hub.org).

  The state is a tuple where the first element is an atom of `:connected` or
  `:disconnected` and the second element is the value of `System.monotonic_time/1`
  at the time of setting the new state.

  This agent is started as a child when using `NervesHub.Supervisor`. However,
  if you are not using the supervisor (i.e. HTTP requests only), you must start
  this agent separately:

  ```elixir
  def init(_) do
    children =
      [
        NervesHub.Connection,
        MyApp.OtherChild
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
  ```

  In practice, this state is set anytime the device connection to
  [nerves-hub.org](https://www.nerves-hub.org) channel changes.
  Likewise, it is set after a HTTP request fails or succeeds. This makes it
  useful when you want to consider the connection to
  [nerves-hub.org](https://www.nerves-hub.org) as part of the overall health
  of the device and perform explicit actions based on the result, such as using
  the Erlang [:heart](http://erlang.org/doc/man/heart.html) module to force a
  reboot if the callback check fails.

  ```
  # Set a callback for heart to check every 5 seconds. If the function returns anything other than
  # `:ok`, it will cause reboot.
  :heart.set_callback(NervesHub.Connection, :check!)
  ```

  Or, you can use the check as part of a separate function with other health checks as well
  ```
  defmodule MyApp.Checker do
    def health_check do
      with :ok <- NervesHub.Connection.check,
           :ok <- MyApp.another_check,
           :ok <- MyApp.yet_another_check,
      do
        :ok
      else
        err -> err
      end
    end
  end

  # Somewhere else in MyApp
  :heart.set_callback(MyApp.Checker, :health_check)
  ```
  """

  use Agent

  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_) do
    # start in a disconnected state
    Agent.start_link(fn -> {:disconnected, current_time()} end, name: __MODULE__)
  end

  @doc """
  A simple check to see if the device is considered ok.

  This will still return `:ok` if the device is in a disconnected state,
  but within the `:connection_timeout` timeframe to allow for
  intermittent connection failures that are recoverable. Once the
  disconnection has exceeded the timeout, this check will be consided
  unhealthy.

  The default connection timeout is 15 minutes (900 seconds), but is configurable:
  ```
  # 60 second timeout
  config :nerves_hub, connection_timeout: 60
  ```
  """
  @spec check() :: :ok | {:error, {:disconnected_too_long, integer()}} | {:error, :no_agent}
  def check() do
    timeout = Application.get_env(:nerves_hub, :connection_timeout, 900)
    now = current_time()

    Agent.get(__MODULE__, & &1)
    |> case do
      {:connected, _} -> :ok
      {:disconnected, time} when now - time <= timeout -> :ok
      {:disconnected, time} -> {:error, {:disconnected_too_long, time}}
    end
  end

  @doc """
  Same as `check/0`, but raises `RuntimeError` if the check fails
  """
  @spec check!() :: :ok
  def check!() do
    unless check() == :ok do
      raise "too much time has passed since a successful connection to NervesHub"
    end

    :ok
  end

  @doc """
  Sets the state to `{:connected, System.monotonic_time(:seconds)}`
  """
  @spec connected() :: :ok | {:error, :no_agent}
  def connected() do
    fun = fn _ -> {:connected, current_time()} end
    apply_agent_fun(:update, fun)
  end

  @doc """
  Sets the state to `{:disconnected, System.monotonic_time(:seconds)}`
  """
  @spec disconnected() :: :ok | {:error, :no_agent}
  def disconnected() do
    # If we are already in a disconnected state, then don't
    # overwrite the existing value so we can measure from
    # the first point of disconnect
    fun = fn state ->
      case state do
        {:disconnected, _time} = state -> state
        _ -> {:disconnected, current_time()}
      end
    end

    apply_agent_fun(:update, fun)
  end

  @doc """
  Reads the state directly without modification.
  """
  @spec read() :: {:connected, integer()} | {:disconnected, integer()} | {:error, :no_agent}
  def read(), do: apply_agent_fun(:get, & &1)

  defp current_time(), do: System.monotonic_time(:second)

  defp apply_agent_fun(fun_name, fun) do
    case Process.whereis(__MODULE__) do
      agent when is_pid(agent) ->
        apply(Agent, fun_name, [agent, fun])

      _ ->
        {:error, :no_agent}
    end
  end
end
