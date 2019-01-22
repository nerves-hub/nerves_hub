defmodule NervesHub.Runtime.NervesKV do
  @moduledoc """
  NervesHub.Runtime implementation for devices that store NervesHub
  information in Nerves.Runtime.KV.
  """

  @behaviour NervesHub.Runtime

  @impl true
  def serial_number() do
    Nerves.Runtime.KV.get("nerves_serial_number")
  end

  @impl true
  def running_firmware_uuid() do
    Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end

  @impl true
  def reboot() do
    Nerves.Runtime.reboot()
  end

  @impl true
  def install_device_path() do
    Nerves.Runtime.KV.get("nerves_fw_devpath") || "/dev/mmcblk0"
  end

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  @impl true
  def device_cert() do
    Nerves.Runtime.KV.get(@cert) |> pem_to_der()
  end

  @impl true
  def device_key() do
    key = Nerves.Runtime.KV.get(@key) |> pem_to_der()
    {:ECPrivateKey, key}
  end

  defp pem_to_der(nil), do: <<>>

  defp pem_to_der(cert) do
    case X509.Certificate.from_pem(cert) do
      {:error, :not_found} -> <<>>
      {:ok, decoded} -> X509.Certificate.to_der(decoded)
    end
  end
end
