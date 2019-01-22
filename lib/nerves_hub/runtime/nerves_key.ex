defmodule NervesHub.Runtime.NervesKey do
  @moduledoc """
  NervesHub.Runtime implementation for devices that store some information
  in NervesKeys.
  """

  @behaviour NervesHub.Runtime

  @impl true
  def serial_number() do
    {:ok, i2c} = ATECC508A.Transport.I2C.init([])
    NervesKey.manufacturer_sn(i2c)
  end

  @impl true
  defdelegate running_firmware_uuid(), to: NervesHub.Runtime.NervesKV

  @impl true
  @spec reboot() :: no_return()
  defdelegate reboot(), to: NervesHub.Runtime.NervesKV

  @impl true
  defdelegate install_device_path(), to: NervesHub.Runtime.NervesKV

  @impl true
  def device_cert() do
    {:ok, i2c} = ATECC508A.Transport.I2C.init([])
    NervesKey.device_cert(i2c) |> X509.Certificate.to_der()
  end

  @impl true
  def device_key() do
    {:ok, engine} = NervesKey.PKCS11.load_engine()
    NervesKey.PKCS11.private_key(engine, {:i2c, 1})
  end
end
