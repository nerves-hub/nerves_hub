defmodule NervesHub.FirmwareChannel do
  use GenServer
  require Logger

  alias NervesHub.{Client, HTTPFwupStream}
  alias PhoenixClient.{Channel, Message}

  @rejoin_after Application.get_env(:nerves_hub, :rejoin_after, 5_000)

  @client Application.get_env(:nerves_hub, :client, Client.Default)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def topic do
    "firmware:" <> Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end

  def join_params do
    %{}
  end

  def init(opts) do
    socket = opts[:socket]
    send(self(), :join)

    {:ok,
     %{
       socket: socket,
       channel: nil,
       params: join_params()
     }}
  end

  def handle_info(%Message{event: "update", payload: params}, state) do
    {:noreply, maybe_update_firmware(params, state)}
  end

  def handle_info(%Message{event: event, payload: payload}, state)
      when event in ["phx_error", "phx_close"] do
    reason = Map.get(payload, :reason, "unknown")
    _ = Client.handle_error(@client, reason)
    Process.send_after(self(), :join, @rejoin_after)
    {:noreply, state}
  end

  def handle_info(:join, %{socket: socket, params: params} = state) do
    case Channel.join(socket, topic(), params) do
      {:ok, reply, channel} ->
        state = %{state | channel: channel}
        {:noreply, maybe_update_firmware(reply, state)}

      _error ->
        Process.send_after(self(), :join, @rejoin_after)
        {:noreply, state}
    end
  end

  def handle_info({:fwup, {:ok, 0, message}}, state) do
    Logger.info("[NervesHub] FWUP Finished")
    _ = Client.handle_fwup_message(@client, message)
    Nerves.Runtime.reboot()
    {:noreply, state}
  end

  def handle_info({:fwup, message}, state) do
    _ = Client.handle_fwup_message(@client, message)
    {:noreply, state}
  end

  def handle_info({:http_error, error}, state) do
    Logger.error("HTTP Stream Error: #{inspect(error)}")
    _ = Client.handle_error(@client, error)
    {:noreply, state}
  end

  def handle_info({:update_reschedule, response}, state) do
    {:noreply, maybe_update_firmware(response, state)}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _, reason}, state) do
    Logger.error("HTTP Stream Error: #{inspect(reason)}")
    _ = Client.handle_error(@client, reason)
    {:stop, reason, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

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
        {:ok, http} = HTTPFwupStream.start_link(self())
        spawn_monitor(HTTPFwupStream, :get, [http, url])
        Logger.info("[NervesHub] Downloading firmware: #{url}")
        state

      :ignore ->
        state

      {:reschedule, ms} ->
        timer = Process.send_after(self(), {:update_reschedule, data}, ms)
        Logger.info("[NervesHub] rescheduling firmware update in #{ms} milliseconds")
        Map.put(state, :update_reschedule_timer, timer)
    end
  end

  defp maybe_update_firmware(_, state), do: state

  defp maybe_cancel_timer(state, key) do
    timer = Map.get(state, key)

    if timer && Process.read_timer(timer) do
      Process.cancel_timer(timer)
    end

    Map.delete(state, :key)
  end
end
