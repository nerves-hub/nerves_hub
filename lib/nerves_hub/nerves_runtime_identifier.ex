defmodule NervesHub.NervesRuntimeIdentifier do
  @doc "The default NervesHub Identifier"
  @behaviour NervesHub.Identifier

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  @impl NervesHub.Identifier
  def get_uuid(), do: Nerves.Runtime.KV.get_active("nerves_fw_uuid")

  @impl NervesHub.Identifier
  def get_cert(), do: Nerves.Runtime.KV.get(@cert)

  @impl NervesHub.Identifier
  def get_key(), do: Nerves.Runtime.KV.get(@key)
end
