defmodule NervesHub do
  alias NervesHub.{FirmwareChannel, ConsoleChannel}

  def connect do
    ConsoleChannel.join()
    FirmwareChannel.join()
  end
end
