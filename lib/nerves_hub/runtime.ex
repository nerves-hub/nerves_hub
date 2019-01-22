defmodule NervesHub.Runtime do
  @moduledoc """
  Module for querying the device for runtime information
  """

  @doc """
  Return this device's serial number
  """
  @spec serial_number() :: String.t()
  def serial_number() do
    Nerves.Runtime.KV.get("nerves_serial_number")
  end

  @doc """
  Return the UUID for the running firmware.
  """
  @spec running_firmware_uuid() :: String.t()
  def running_firmware_uuid() do
    Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end
end
