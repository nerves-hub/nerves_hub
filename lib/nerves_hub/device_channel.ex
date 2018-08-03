defmodule NervesHub.DeviceChannel do
  use PhoenixChannelClient
  require Logger

  alias NervesHub.HTTPClient

  def handle_in("update", params, state) do
    {:noreply, update_firmware(params, state)}
  end

  def handle_in(event, payload, state) do
    Logger.info("Handle In: #{inspect(event)} #{inspect(payload)}")
    {:noreply, state}
  end

  def handle_reply(
        {:ok, :join, %{"response" => response, "status" => "ok"}, _},
        state
      ) do
    Logger.info("Joined channel: #{inspect response}")
    {:noreply, update_firmware(response, state)}
  end

  def handle_reply(payload, state) do
    Logger.info("Handle Reply: #{inspect(payload)}")
    {:noreply, state}
  end

  def handle_close(payload, state) do
    Logger.info("Handle close: #{inspect(payload)}")
    {:noreply, state}
  end

  def handle_info({:fwup, :done}, state) do
    Logger.debug "FWUP Finished"
    Nerves.Runtime.reboot()
    {:noreply, state}
  end

  defp update_firmware(%{"firmware_url" => url}, state) do
    {:ok, http} = HTTPClient.start_link(self())
    HTTPClient.get(http, url)
    Logger.info("Downloading firmware: #{url}")
    state
  end

  defp update_firmware(_, state), do: state
end
