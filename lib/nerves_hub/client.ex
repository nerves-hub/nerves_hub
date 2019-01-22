defmodule NervesHub.Client do
  @moduledoc """
  A behaviour module for customizing if and when firmware updates get applied.

  By default NervesHub applies updates as soon as it knows about them from the
  NervesHub server and doesn't give warning before rebooting. This let's
  devices hook into the decision making process and monitor the update's
  progress.

  # Example

  ```elixir
  defmodule MyApp.NervesHubClient do
    @behaviour NervesHub.Client

    # May return:
    #  * `:apply` - apply the action immediately
    #  * `:ignore` - don't apply the action, don't ask again.
    #  * `{:reschedule, timeout_in_milliseconds}` - call this function again later.

    @impl NervesHub.Client
    def update_available(data) do
      if SomeInternalAPI.is_now_a_good_time_to_update?(data) do
        :apply
      else
        {:reschedule, 60_000}
      end
    end
  end
  ```

  To have NervesHub invoke it, add the following to your `config.exs`:

  ```elixir
  config :nerves_hub, client: MyApp.NervesHubClient
  ```
  """

  require Logger

  @typedoc "Update that comes over a socket."
  @type update_data :: map()

  @typedoc "Supported responses from `update_available/1`"
  @type update_response :: :apply | :ignore | {:reschedule, pos_integer()}

  @typedoc "Firmware update progress, completion or error report"
  @type fwup_message ::
          {:ok, non_neg_integer(), String.t()}
          | {:warning, non_neg_integer(), String.t()}
          | {:error, non_neg_integer(), String.t()}
          | {:progress, 0..100}

  @doc """
  Called to find out what to do when a firmware update is available.

  May return one of:

  * `apply` - Download and apply the update right now.
  * `ignore` - Don't download and apply this update.
  * `{:reschedule, timeout}` - Defer making a decision. Call this function again in `timeout` milliseconds.
  """
  @callback update_available(update_data()) :: update_response()

  @doc """
  Called on firmware update reports.

  The return value of this function is not checked.
  """
  @callback handle_fwup_message(fwup_message()) :: :ok

  @doc """
  Called when downloading a firmware update fails.

  The return value of this function is not checked.
  """
  @callback handle_error(any()) :: :ok

  @doc """
  This function is called internally by NervesHub to notify clients.
  """
  @spec dispatch_update_available(update_data()) :: update_response()
  def dispatch_update_available(data) do
    case apply_wrap(:update_available, [data]) do
      :apply ->
        :apply

      :ignore ->
        :ignore

      {:reschedule, timeout} when timeout > 0 ->
        {:reschedule, timeout}

      wrong ->
        Logger.error(
          "[NervesHub] Client: #{client()}.update_available/1 bad return value: #{inspect(wrong)} Applying update."
        )

        :apply
    end
  end

  @doc """
  This function is called internally by NervesHub to notify clients of fwup progress.
  """
  @spec dispatch_fwup_message(fwup_message()) :: :ok
  def dispatch_fwup_message(data) do
    _ = apply_wrap(:handle_fwup_message, [data])
    :ok
  end

  @doc """
  This function is called internally by NervesHub to notify clients of fwup errors.
  """
  @spec dispatch_error(any()) :: :ok
  def dispatch_error(data) do
    _ = apply_wrap(:handle_error, [data])
  end

  # Catches exceptions and exits
  defp apply_wrap(function, args) do
    apply(client(), function, args)
  catch
    :error, reason -> {:error, reason}
    :exit, reason -> {:exit, reason}
    err -> err
  end

  defp client() do
    Application.get_env(:nerves_hub, :client)
  end
end
