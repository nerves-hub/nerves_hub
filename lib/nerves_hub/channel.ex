defmodule NervesHub.Channel do
  use GenServer
  require Logger

  alias NervesHub.{Client, HTTPFwupStream}
  alias PhoenixClient.{Channel, Message}

  @rejoin_after Application.get_env(:nerves_hub, :rejoin_after, 5_000)

  @client Application.get_env(:nerves_hub, :client, Client.Default)

  defmodule State do
    @type status ::
            :idle
            | :fwup_error
            | :update_failed
            | :update_rescheduled
            | {:updating, integer()}
            | :unknown

    @type t :: %__MODULE__{
            channel: pid(),
            connected?: boolean(),
            params: map(),
            status: status(),
            socket: pid(),
            topic: String.t()
          }

    defstruct socket: nil,
              topic: "device",
              channel: nil,
              params: %{},
              status: :idle,
              connected?: false
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    send(self(), :join)
    {:ok, struct(State, opts)}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_info(%Message{event: "reboot"}, state) do
    Logger.warn("Reboot Request from NervesHub")
    Channel.push_async(state.channel, "rebooting", %{})
    # TODO: Maybe allow delayed reboot
    Nerves.Runtime.reboot()
    {:noreply, state}
  end

  def handle_info(%Message{event: "update", payload: params}, state) do
    {:noreply, maybe_update_firmware(params, state)}
  end

  def handle_info(%Message{event: event, payload: payload}, state)
      when event in ["phx_error", "phx_close"] do
    reason = Map.get(payload, :reason, "unknown")
    NervesHub.Connection.disconnected()
    _ = Client.handle_error(@client, reason)
    Process.send_after(self(), :join, @rejoin_after)
    {:noreply, %{state | connected?: false}}
  end

  def handle_info(:join, %{socket: socket, topic: topic, params: params} = state) do
    case Channel.join(socket, topic, params) do
      {:ok, reply, channel} ->
        NervesHub.Connection.connected()
        state = %{state | channel: channel, connected?: true}
        {:noreply, maybe_update_firmware(reply, state)}

      _error ->
        NervesHub.Connection.disconnected()
        Process.send_after(self(), :join, @rejoin_after)
        {:noreply, %{state | connected?: false}}
    end
  end

  def handle_info({:fwup, {:ok, 0, message}}, state) do
    Logger.info("[NervesHub] FWUP Finished")
    _ = Client.handle_fwup_message(@client, message)
    Nerves.Runtime.reboot()
    {:noreply, state}
  end

  def handle_info({:fwup, message}, state) do
    state =
      case message do
        {:progress, percent} ->
          Channel.push_async(state.channel, "fwup_progress", %{value: percent})
          %{state | status: {:updating, percent}}

        {:error, _, _message} ->
          Channel.push_async(state.channel, "status_update", %{status: "fwup error"})
          %{state | status: :fwup_error}

        _ ->
          state
      end

    _ = Client.handle_fwup_message(@client, message)
    {:noreply, state}
  end

  def handle_info({:http_error, error}, state) do
    _ = Client.handle_error(@client, error)
    Channel.push_async(state.channel, "status_update", %{status: "update failed"})
    {:noreply, %{state | status: :update_failed}}
  end

  def handle_info({:update_reschedule, response}, state) do
    {:noreply, maybe_update_firmware(response, state)}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _, reason}, state) do
    Logger.error("HTTP Streaming Error: #{inspect(reason)}")
    _ = Client.handle_error(@client, reason)
    Channel.push_async(state.channel, "status_update", %{status: "update failed"})
    {:noreply, %{state | status: :update_failed}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state), do: NervesHub.Connection.disconnected()

  defp maybe_update_firmware(%{"firmware_url" => url} = data, state) do
    # Cancel an existing timer if it exists.
    # This prevents rescheduled updates`
    # from compounding.
    state = maybe_cancel_timer(state, :update_reschedule_timer)

    # possibly offload update decision to an external module.
    # This will allow application developers
    # to control exactly when an update is applied.
    case Client.update_available(@client, data) do
      :apply ->
        {:ok, http} = HTTPFwupStream.start(self())
        spawn_monitor(HTTPFwupStream, :get, [http, url])
        Logger.info("[NervesHub] Downloading firmware: #{url}")
        %{state | status: {:updating, 0}}

      :ignore ->
        state

      {:reschedule, ms} ->
        timer = Process.send_after(self(), {:update_reschedule, data}, ms)
        Logger.info("[NervesHub] rescheduling firmware update in #{ms} milliseconds")
        Map.put(state, :update_reschedule_timer, timer)
        %{state | status: :update_rescheduled}
    end
  end

  defp maybe_update_firmware(_, state), do: state

  defp maybe_cancel_timer(state, key) do
    timer = Map.get(state, key)

    if timer && Process.read_timer(timer) do
      Process.cancel_timer(timer)
    end

    Map.delete(state, key)
  end
end
