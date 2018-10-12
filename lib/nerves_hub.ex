defmodule NervesHub do
  require Logger
  alias NervesHub.{FirmwareChannel, HTTPClient, HTTPFwupStream}

  def connect do
    FirmwareChannel.join()
  end

  def update do
    case HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => true, "firmware_url" => url}}} ->
        {:ok, http} = HTTPFwupStream.start_link(self())
        HTTPFwupStream.get(http, url)
        Logger.info("[NervesHub] Downloading firmware: #{url}")

        receive do
          {:fwup, :done} -> Nerves.Runtime.reboot()
          {:error, _} = err -> err
        end

      {:ok, %{"update_available" => false}} ->
        :no_update

      {:error, _} = err ->
        err
    end
  end
end
