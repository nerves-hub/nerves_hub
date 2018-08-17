defmodule NervesHub do
  alias NervesHub.FirmwareChannel

  def connect do
    FirmwareChannel.join()
  end
end
