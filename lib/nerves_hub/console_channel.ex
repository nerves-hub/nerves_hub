defmodule NervesHub.ConsoleChannel do
  use GenServer
  require Logger

  @moduledoc """
  Wraps IEx.Server setting this process as the group_leader.
  This allows tunneling the `io_request`'s over the channel socket.

  The remote console ability is disabled by default and requires the
  `remote_iex` key to be enabled in the config:
  ```
  config :nerves_hub, remote_iex: true
  ```

  Once connected, IO requests on the device will be pushed up the socket
  for the following events:

  * `get_line` - IO is requesting the next line from user input.
  Typically just `iex () >`
  * `put_chars` - Display the sepcified characters from the IEx Server for user review
    * This requires an immediate reply of `:ok` and then IEx will send a `:get_line`
    request to await the user input. NervesHubWeb handles immediately replies `:ok`
    to these events (see below)
  * `init_attempt` - Pushed asynchronously after attempting to init an IEx Server.
  Payload has a `success` key with a boolean value to specify whether the server
  process was started successfully or not 

  The following events are supported _from_ the socket:

  * `iex_terminate` - Kill any running IEx server in the channel
  * `init` - The console channel starts without a linked IEx Server by default.
  This must be called before sending I/O back and forth. Only one IEx Server is
  initialized for this channel. If IEx Server has already been initialized and
  is in a good state, then calling `init` will continue to use the linked session
  and have no effect. 
  * `io_reply` - Send the reply characters to the IO. Requires specific keys in payload   
    * `kind` - event that you're replying to. Either `get_line` or `put_chars`
    * `data` - characters to be put into the IO. `put_chars` requires this to be `ok` or `error`
  * `phx_close` or `phx_error` - This will cause the channel to attempt rejoining
  every 5 seconds. You can change the rejoin timing in the config
  ```
  config :nerves_hub, rejoin_after: 3_000
  ```

  For more info, see [The Erlang I/O Protocol](http://erlang.org/doc/apps/stdlib/io_protocol.html)
  """

  alias PhoenixClient.{Channel, Message}
  alias NervesHub.Client

  @client Application.get_env(:nerves_hub, :client, Client.Default)
  @rejoin_after Application.get_env(:nerves_hub, :rejoin_after, 5_000)

  defmodule State do
    defstruct socket: nil,
              topic: "console",
              channel: nil,
              params: [],
              iex_pid: nil,
              request: nil,
              retry_count: 0
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def init(opts) do
    state = State.__struct__(opts)
    send(self(), :join)

    {:ok, state}
  end

  def handle_info(:join, %{socket: socket, topic: topic, params: params} = state) do
    case Channel.join(socket, topic, params) do
      {:ok, _reply, channel} ->
        {:noreply, %{state | channel: channel}}

      _error ->
        Process.send_after(self(), :join, @rejoin_after)
        {:noreply, state}
    end
  end

  def handle_info(%Message{event: "iex_terminate"}, state) do
    Process.exit(state.iex_pid, :kill)
    {:noreply, %{state | iex_pid: nil}}
  end

  def handle_info(%Message{event: "init"}, state), do: create_or_reuse_iex_server(state)

  def handle_info(%Message{event: "io_reply", payload: %{"data" => data, "kind" => kind}}, state) do
    {from, reply_as, _} = state.request
    data = if kind == "put_chars", do: String.to_existing_atom(data), else: data
    io_reply(from, reply_as, data)
    {:noreply, state}
  end

  def handle_info(%Message{event: event, payload: payload}, state)
      when event in ["phx_error", "phx_close"] do
    reason = Map.get(payload, :reason, "unknown")
    _ = Client.handle_error(@client, reason)
    Process.send_after(self(), :join, @rejoin_after)
    {:noreply, state}
  end

  # Handle IO Request from IEx Server
  def handle_info({:io_request, from, reply_as, request}, state) do
    state = io_request(from, reply_as, request, state)
    {:noreply, state}
  end

  def handle_info(req, state) do
    Client.handle_error(@client, "Unhandled Console handle_info - #{inspect(req)}")
    {:noreply, state}
  end

  defp create_or_reuse_iex_server(%{iex_pid: iex_pid} = state) when is_pid(iex_pid) do
    with true <- Process.alive?(state.iex_pid),
         {:group_leader, gl_pid} <- Process.info(state.iex_pid, :group_leader),
         true <- gl_pid == self() do
      # We already have an IEx Server running, so keep using it
      {:noreply, state}
    else
      _err ->
        Client.handle_error(@client, "IEx Group Leader changed or died. Restarting")
        Process.exit(state.iex_pid, :kill)
        # restart IEx process
        create_or_reuse_iex_server(%{state | iex_pid: nil})
    end
  end

  defp create_or_reuse_iex_server(state) do
    iex_pid = spawn_link(fn -> IEx.Server.run([]) end)
    success? = Process.group_leader(iex_pid, self())

    # Ack back if group_leader successfully assigned and let
    # requestor handle error case
    Channel.push_async(state.channel, "init_attempt", %{success: success?})

    {:noreply, %{state | iex_pid: iex_pid}}
  end

  # Send IO Reply to IEx server
  defp io_reply(from, reply_as, reply), do: send(from, {:io_reply, reply_as, reply})

  ##
  # Match the :io_request commands from IEx Server
  #

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

  # All other requests push IO Request over the socket. 
  defp io_request(from, reply_as, {:get_line, encoding, data} = req, state) do
    Channel.push_async(state.channel, "get_line", %{encoding: encoding, data: data})
    %{state | request: {from, reply_as, req}}
  end

  defp io_request(from, reply_as, {:put_chars, encoding, data} = req, state) do
    case Channel.push(state.channel, "put_chars", %{encoding: encoding, data: data}) do
      {:ok, %{}} ->
        io_reply(from, reply_as, :ok)

      error ->
        if state.retry_count >= 10, do: raise("Cannot send IO through channel - Is it connected?")
        Client.handle_error(@client, error)
        io_request(from, reply_as, req, %{state | retry_count: state.retry_count + 1})
    end

    %{state | request: {from, reply_as, req}, retry_count: 0}
  end

  defp io_request(_, _, req, state) do
    Client.handle_error(@client, "Unknown IO Request !! - #{inspect(req)}")
    state
  end
end
