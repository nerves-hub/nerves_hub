defmodule NervesHubClient do
  alias NervesHubClient.{Socket, DeviceChannel}

  def connect do
    {:ok, _socket} = Socket.start_link()

    {:ok, _channel} =
      DeviceChannel.start_link(socket: NervesHubClient.Socket, topic: "device:device-1234")

    %{uuid: Nerves.Runtime.KV.get_active(:nerves_fw_uuid)}
    |> DeviceChannel.join()
  end
end
