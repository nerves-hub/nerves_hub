defmodule NervesHub.Client do
  alias NervesHub.Client.{Socket, DeviceChannel}

  def connect do
    {:ok, _socket} = Socket.start_link()

    {:ok, _channel} =
      DeviceChannel.start_link(socket: NervesHub.Client.Socket, topic: "device:lobby")

    DeviceChannel.join()
  end
end
