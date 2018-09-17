defmodule NervesHub.Identifier do
  @moduledoc """
  Behaviour for identifying a device.
  """
  @default_identifier NervesHub.NervesRuntimeIdentifier

  @type uuid() :: binary()

  @type cert() :: binary()

  @type key() :: binary()

  @doc "Should return a binary firmware UUID"
  @callback get_uuid() :: uuid()

  @doc "Should return a text cert"
  @callback get_cert() :: cert()

  @doc "Shoudl return a text key"
  @callback get_key() :: key()

  @doc "Returns the uuid of the current device"
  def get_uuid(), do: identifier().get_uuid()

  @doc "Returns the ssl cert of the current device"
  def get_cert(), do: identifier().get_cert()

  @doc "Returns the key of the current device"
  def get_key(), do: identifier().get_key()

  defp identifier() do
    Application.get_env(:nerves_hub, :identifier, @default_identifier)
  end
end
