defmodule NervesHub.Certificate do
  @public_keys Application.get_env(:nerves_hub, :fwup_public_keys, [])
               |> NervesHubCLI.resolve_fwup_public_keys()

  ca_cert_path =
    System.get_env("NERVES_HUB_CA_CERTS") || Application.get_env(:nerves_hub, :ca_certs) ||
      Application.app_dir(:nerves_hub, "priv", "ca_certs")

  ca_certs =
    ca_cert_path
    |> File.ls!()
    |> Enum.map(&File.read!(Path.join(ca_cert_path, &1)))
    |> Enum.map(&X509.Certificate.to_der(X509.Certificate.from_pem!(&1)))

  @ca_certs ca_certs

  def ca_certs() do
    @ca_certs
  end

  def fwup_public_keys() do
    @public_keys
  end
end
