defmodule NervesHub.FirmwareChannel do
  use PhoenixChannelClient
  require Logger

  alias NervesHub.{Client, HTTPFwupStream}

  @rejoin_after Application.get_env(:nerves_hub, :rejoin_after, 5_000)

  @client Application.get_env(:nerves_hub, :client, Client.Default)

  def topic do
    "firmware:" <> Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end

  def handle_in("update", params, state) do
    {:noreply, maybe_update_firmware(params, state)}
  end

  def handle_in(_event, _payload, state) do
    {:noreply, state}
  end

  def handle_reply(
        {:ok, :join, %{"response" => response, "status" => "ok"}, _},
        state
      ) do
    {:noreply, maybe_update_firmware(response, state)}
  end

  def handle_reply(
        {:error, :join, %{"response" => %{"reason" => reason}, "status" => "error"}},
        state
      ) do
    _ = Client.handle_error(@client, reason)
    {:stop, reason, state}
  end

  def handle_reply(_payload, state) do
    {:noreply, state}
  end

  def handle_close(_payload, state) do
    Process.send_after(self(), :rejoin, @rejoin_after)
    {:noreply, state}
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
