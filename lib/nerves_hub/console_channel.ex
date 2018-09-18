defmodule NervesHub.ConsoleChannel do
  @moduledoc """
  Wraps IEx.Server setting this process as the group_leader.
  This allows tunneling the `io_request`s over the channel socket.

  The basic layout is:

  `NervesHub.ConsoleChannel` (this process) ==> `NervesHubDeviceWww.ConsoleChannel`
                                                        ||
                                                        ||
                                                        ||
                                                        \\/
                                              NervesHubCore.DeviceConsole
                                                        /\\
                                                        ||
                                                        ||
                                                        ||
  `console.html` (javascript/frontend) =======> `NervesHubWebWww.ConsoleChannel`

  Commands are sent over their respective socket and coordinated via NervesHubCore.DeviceConsole.

  commands are shaped like:
    * event - "io_request:" <> kind
      * kind is any of the commands handled by a `group_leader`
        At least these need to be implemented:
        * `put_chars`
        * `get_line`
    * payload - `%{"data" => data}`
      * `data` varies per `kind`.
        * `put_chars` request data is a binary to be written to the console.
        * `put_chars` response is an `"ok"` or `"error"` binary.
        * `get_chars` request data is a binary to prompt on the console.
        * `get_chars` response data is a binary to be processed by `IEx.Server`.
  """
  use PhoenixChannelClient

  def topic do
    "console:" <> Nerves.Runtime.KV.get("nerves_serial_number")
  end

  def iex_init_callback() do
    :ok
  end

  def init_iex(state) do
    true = :erlang.group_leader(self(), self())

    iex_pid =
      spawn_link(fn ->
        IEx.Server.start([], {__MODULE__, :iex_init_callback, []})
      end)

    state
    |> Map.put(:iex_pid, iex_pid)
    |> Map.put(:requests, nil)
  end

  def handle_in("connect", _, state) do
    {:noreply, init_iex(state)}
  end

  def handle_in(
        "io_response:" <> "put_chars",
        %{"data" => data},
        %{request: _, iex_pid: _} = state
      ) do
    {from, reply_as, {:put_chars, _, _}} = state.request
    io_reply(from, reply_as, String.to_atom(data))
    {:noreply, %{state | request: nil}}
  end

  def handle_in(
        "io_response:" <> "get_line",
        %{"data" => data},
        %{request: _, iex_pid: _} = state
      ) do
    {from, reply_as, {:get_line, _, _}} = state.request
    io_reply(from, reply_as, data)
    {:noreply, %{state | request: nil}}
  end

  def handle_in(event, payload, state) do
    {:stop, {:unhandled_event, event, payload}, state}
  end

  def handle_reply(
        {:ok, :join, %{"response" => _response, "status" => "ok"}, _},
        state
      ) do
    {:noreply, state}
  end

  def handle_reply(
        {:error, :join, %{"response" => %{"reason" => reason}, "status" => "error"}},
        state
      ) do
    {:stop, reason, state}
  end

  def handle_reply(_, state) do
    {:noreply, state}
  end

  def handle_close(_payload, state) do
    Process.send_after(self(), :rejoin, 5_000)
    {:noreply, state}
  end

  # This is the group_leader message.
  def handle_info({:io_request, from, reply_as, req}, state) do
    state = io_request(from, reply_as, req, state)
    {:noreply, state}
  end

  # Matches all the :io_request commands.
  # This is not definitive. These are just the ones for
  # Basic IEx interaction.

  # :setopts not supported
  defp io_request(from, reply_as, {:setopts, _opts}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    state
  end

  # :getopts not supported
  defp io_request(from, reply_as, :getopts, state) do
    reply = {:ok, [binary: true, encoding: :unicode]}
    io_reply(from, reply_as, reply)
    state
  end

  # :get_geometry not supported
  defp io_request(from, reply_as, {:get_geometry, :columns}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    state
  end

  defp io_request(from, reply_as, {:get_geometry, :rows}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    state
  end

  # All other requests push 
  # a command over the socket. 
  defp io_request(from, reply_as, req, state) do
    # FIXME(Connor) 18-09-17
    # This function needs to be spawned because
    # it calls the `push` function, which 
    # is a GenServer call. There may be a better solution for
    # this.
    request = {from, reply_as, req}
    spawn_link(__MODULE__, :push_request, [from, reply_as, req])
    Map.put(state, :request, request)
  end

  # Pushes an io_request onto the socket.
  # will be published as event="io_request:" <> command with a map payload
  # of the arguments. 
  def push_request(_from, _reply_as, {:put_chars, :unicode, msg}) do
    push("io_request:put_chars", %{data: msg, encoding: "unicode"})
  end

  def push_request(_from, _reply_as, {:put_chars, :latin1, msg}) do
    push("io_request:put_chars", %{data: msg, encoding: "latin1"})
  end

  def push_request(_from, _reply_as, {:get_line, :unicode, msg}) do
    push("io_request:get_line", %{data: msg})
  end

  defp io_reply(from, reply_as, reply), do: send(from, {:io_reply, reply_as, reply})
end
