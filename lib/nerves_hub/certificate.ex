defmodule NervesHub.Certificate do
  @public_keys Application.get_env(:nerves_hub, :public_keys, [])
               |> NervesHubCLI.public_keys()

  ca_cert_path =
    Application.get_env(:nerves_hub, :ca_certs) || System.get_env("NERVES_HUB_CA_CERTS") ||
      :code.priv_dir(:nerves_hub)
      |> to_string()
      |> Path.join("ca_certs")

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

  def public_keys do
    @public_keys
  end
end
