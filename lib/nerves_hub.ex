defmodule NervesHub do
  alias NervesHub.{Socket, DeviceChannel}

  def connect do
    {:ok, _socket} = Socket.start_link()

    {:ok, _channel} =
      DeviceChannel.start_link(socket: NervesHub.Socket, topic: "device:device-1234")

    %{uuid: Nerves.Runtime.KV.get_active(:nerves_fw_uuid)}
    |> DeviceChannel.join()
  end

  def home_dir do
    System.get_env("NERVES_HUB_HOME") || 
    Path.expand("~/.nerves_hub")
  end
end
