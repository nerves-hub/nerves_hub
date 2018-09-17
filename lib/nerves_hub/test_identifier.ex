defmodule NervesHub.TestIdentifier do
  @moduledoc "Host/Test identifier."
  @behaviour NervesHub.Identifier
  @error """
  Test Identifier was not configured correctly. Configure it in
  your config.exs file:

  config :nerves_hub, NervesHub.TestIdentifier,
    uuid: "some uuid",
    cert: "binary cert file",
    key: "binary key file"
  """

  @impl NervesHub.Identifier
  def get_uuid(),
    do: Application.get_env(:nerves_hub, __MODULE__, [])[:uuid] || raise(@error)

  @impl NervesHub.Identifier
  def get_cert(),
    do: Application.get_env(:nerves_hub, __MODULE__, [])[:cert] || raise(@error)

  @impl NervesHub.Identifier
  def get_key(),
    do: Application.get_env(:nerves_hub, __MODULE__, [])[:key] || raise(@error)
end
