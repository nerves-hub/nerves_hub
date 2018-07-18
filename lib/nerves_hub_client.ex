defmodule NervesHubClient do
  alias NervesHubClient.{Socket, DeviceChannel}

  def connect do
    {:ok, _socket} = Socket.start_link()

    {:ok, _channel} =
      DeviceChannel.start_link(socket: NervesHubClient.Socket, topic: "device:device-1234")

    DeviceChannel.join()
  end
end
