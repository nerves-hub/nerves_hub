defmodule NervesHub.Runtime do
  @moduledoc """
  Module for querying the device for runtime information
  """

  @doc """
  Return this device's serial number
  """
  @callback serial_number() :: String.t()

  @doc """
  Return the UUID for the running firmware.
  """
  @callback running_firmware_uuid() :: String.t()

  @doc """
  Initiate a reboot.
  """
  @callback reboot() :: no_return()

  @doc """
  Return the installation path to use for fwup.
  """
  @callback install_device_path() :: Path.t()

  @callback device_cert() :: binary()
  @callback device_key() :: binary()
end
