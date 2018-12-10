defmodule NervesHub.Certificate do
  def pem_to_der(<<"-----BEGIN", _rest::binary>> = cert) do
    [{_, cert, _}] = :public_key.pem_decode(cert)
    cert
  end

  def pem_to_der(nil), do: ""
  def pem_to_der(""), do: ""

  def ca_certs do
    ca_cert_path =
      if cert_path = Application.get_env(:nerves_hub, :ca_certs) do
        cert_path
      else
        :code.priv_dir(:nerves_hub)
        |> to_string()
        |> Path.join("ca_certs")
      end

    ca_cert_path
    |> File.ls!()
    |> Enum.map(&File.read!(Path.join(ca_cert_path, &1)))
    |> Enum.map(&pem_to_der/1)
  end
end
