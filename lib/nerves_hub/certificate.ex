defmodule NervesHub.Certificate do
  # Get the fwup public keys from the app environment. Support the
  # old name of `:public_keys` for now.
  @public_keys Application.get_env(
                 :nerves_hub,
                 :fwup_public_keys,
                 Application.get_env(:nerves_hub, :public_keys, [])
               )
               |> NervesHubCLI.resolve_fwup_public_keys()

  ca_cert_path =
    System.get_env("NERVES_HUB_CA_CERTS") || Application.get_env(:nerves_hub, :ca_certs) ||
      Application.app_dir(:nerves_hub, "priv", "ca_certs")

  ca_certs =
    ca_cert_path
    |> File.ls!()
    |> Enum.map(&File.read!(Path.join(ca_cert_path, &1)))
    |> Enum.map(fn
      <<"-----BEGIN", _rest::binary>> = cert ->
        [{_, cert, _}] = :public_key.pem_decode(cert)
        cert

      _ ->
        ""
    end)

  @ca_certs ca_certs

  def pem_to_der(<<"-----BEGIN", _rest::binary>> = cert) do
    [{_, cert, _}] = :public_key.pem_decode(cert)
    cert
  end

  def pem_to_der(nil), do: ""
  def pem_to_der(""), do: ""

  def ca_certs do
    @ca_certs
  end

  @deprecated "Use fwup_public_keys/0 instead"
  def public_keys do
    fwup_public_keys()
  end

  def fwup_public_keys do
    @public_keys
  end
end
