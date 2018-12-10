defmodule NervesHub do
  @on_load :on_load

  require Logger

  alias NervesHub.{FirmwareChannel, HTTPClient, HTTPFwupStream, Client}

  @client Application.get_env(:nerves_hub, :client, Client.Default)

  def on_load() do
    if Code.ensure_loaded?(NervesHubCLI) do
      current_keys = public_keys()

      new_keys =
        Application.get_env(:nerves_hub, :public_keys, [])
        |> NervesHubCLI.public_keys()

      if current_keys == new_keys do
        :ok
      else
        keys = Enum.join(new_keys, "\n")
        File.write!(public_keys_file(), keys, [:write])
      end
    end
  end

  def connect do
    PhoenixChannelClient.join(FirmwareChannel)
  end

  def update do
    case HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => true, "firmware_url" => url}}} ->
        Logger.info("[NervesHub] Downloading firmware: #{url}")
        {:ok, http} = HTTPFwupStream.start_link(self())
        # Spawn to allow async messages from FWUP.
        spawn_monitor(HTTPFwupStream, :get, [http, url])
        update_receive()

      {:ok, %{"update_available" => false}} ->
        :no_update

      {:error, _} = err ->
        err
    end
  end

  def update_receive() do
    receive do
      # Reboot when FWUP is done applying the update.
      {:fwup, {:ok, 0, ""}} ->
        Logger.info("[NervesHub] Firmware download complete")
        Nerves.Runtime.reboot()

      # Allow client to handle other FWUP message.
      {:fwup, msg} ->
        _ = Client.handle_fwup_message(@client, msg)
        update_receive()

      # If the HTTP stream finishes before fwup, just
      # Wait for FWUP to finish.
      {:DOWN, _, :process, _, :normal} ->
        update_receive()

      # If the HTTP stream fails with an error,
      # return
      {:DOWN, _, :process, _, reason} ->
        {:error, reason}
    end
  end

  def public_keys(key_file \\ nil) do
    key_file = key_file || public_keys_file()

    case File.read(key_file) do
      {:ok, keys} -> String.split(keys)
      _ -> []
    end
  end

  def public_keys_file do
    :nerves_hub
    |> :code.priv_dir()
    |> to_string()
    |> Path.join("public_keys")
  end
end
