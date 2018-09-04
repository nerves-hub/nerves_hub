defmodule NervesHub.FirmwareChannel do
  use PhoenixChannelClient
  require Logger

  alias NervesHub.HTTPClient

  def topic do
    "firmware:" <> Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end

  def handle_in("update", params, state) do
    {:noreply, update_firmware(params, state)}
  end

  def handle_in(_event, _payload, state) do
    {:noreply, state}
  end

  def handle_reply(
        {:ok, :join, %{"response" => response, "status" => "ok"}, _},
        state
      ) do
    {:noreply, update_firmware(response, state)}
  end

  def handle_reply(
        {:error, :join, %{"response" => %{"reason" => reason}, "status" => "error"}},
        state
      ) do
    {:stop, reason, state}
  end

  def handle_reply(_payload, state) do
    {:noreply, state}
  end

  def handle_close(_payload, state) do
    Process.send_after(self(), :rejoin, 5_000)
    {:noreply, state}
  end

  def handle_info({:fwup, :done}, state) do
    Logger.info("[NervesHub] FWUP Finished")
    Nerves.Runtime.reboot()
    {:noreply, state}
  end

  defp update_firmware(%{"firmware_url" => url}, state) do
    {:ok, http} = HTTPClient.start_link(self())
    HTTPClient.get(http, url)
    Logger.info("[NervesHub] Downloading firmware: #{url}")
    state
  end

  defp update_firmware(_, state), do: state
end
