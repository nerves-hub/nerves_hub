defmodule NervesHub do
  alias NervesHub.{Socket, DeviceChannel}

  def connect do
    {:ok, _socket} = Socket.start_link()

    {:ok, _channel} =
      DeviceChannel.start_link(socket: NervesHub.Socket, topic: DeviceChannel.topic())

    DeviceChannel.join()
  end
end
