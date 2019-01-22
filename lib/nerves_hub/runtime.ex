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

  @doc """
  Initiate a reboot.
  """
  @spec reboot() :: no_return()
  def reboot() do
    Nerves.Runtime.reboot()
  end

  @doc """
  Return the installation path to use for fwup.
  """
  @spec install_device_path() :: Path.t()
  def install_device_path() do
    Nerves.Runtime.KV.get("nerves_fw_devpath") || "/dev/mmcblk0"
  end

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  def device_cert() do
    Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()
  end

  def device_key() do
    key = Nerves.Runtime.KV.get(@key) |> Certificate.pem_to_der()
    {:ECPrivateKey, key}
  end

end
