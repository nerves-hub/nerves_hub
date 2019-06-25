defmodule NervesHub do
  require Logger

  alias NervesHub.{HTTPClient, HTTPFwupStream, Client}

  @client Application.get_env(:nerves_hub, :client, Client.Default)

  @doc """
  Checks if the device is connected to the NervesHub channel.
  """
  @spec connected? :: boolean()
  def connected?() do
    channel_state()
    |> Map.get(:connected?, false)
  end

  @doc """
  Current status of the device channel
  """
  @spec status :: NervesHub.Channel.State.status()
  def status() do
    channel_state()
    |> Map.get(:status, :unknown)
  end

  def update do
    case HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => true, "firmware_url" => url}}} ->
        Logger.info("[NervesHub] Downloading firmware: #{url}")
        {:ok, http} = HTTPFwupStream.start_link(self())
        # Spawn to allow async messages from FWUP.
        spawn_monitor(HTTPFwupStream, :get, [http, url])
        update_receive()

      {:ok, %{"data" => %{"update_available" => false}}} ->
        :no_update

      {:error, _} = err ->
        err
    end
  end

  def update_receive() do
    receive do
      # Reboot when FWUP is done applying the update.
      {:fwup, {:ok, 0, message}} ->
        Logger.info("[NervesHub] Firmware download complete")
        _ = Client.handle_fwup_message(@client, message)
        Nerves.Runtime.reboot()

      # Allow client to handle other FWUP message.
      {:fwup, msg} ->
        _ = Client.handle_fwup_message(@client, msg)
        update_receive()

      {:http_error, error} ->
        _ = Client.handle_error(@client, error)
        {:error, {:http_error, error}}

      # If the HTTP stream finishes before fwup, just
      # Wait for FWUP to finish.
      {:DOWN, _, :process, _, :normal} ->
        update_receive()

      # If the HTTP stream fails with an error,
      # return
      {:DOWN, _, :process, _, error} ->
        _ = Client.handle_error(@client, error)
        error
    end
  end

  defp channel_state() do
    GenServer.whereis(NervesHub.Channel)
    |> case do
      channel when is_pid(channel) -> GenServer.call(channel, :get_state)
      _ -> %{}
    end
  end
end
