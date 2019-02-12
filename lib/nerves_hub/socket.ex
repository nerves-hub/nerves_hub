defmodule NervesHub.Socket do
  alias NervesHub.Certificate

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  def opts(nil), do: opts([])

  def opts(user_config) when is_list(user_config) do
    ca_certs = user_config[:cacerts] || Certificate.ca_certs()

    {cert_key, cert_value} = cert(user_config)
    {key_key, key_value} = key(user_config)

    server_name = Application.get_env(:nerves_hub, :device_api_host)
    server_port = Application.get_env(:nerves_hub, :device_api_port)
    sni = Application.get_env(:nerves_hub, :device_api_sni)

    url = "wss://#{server_name}:#{server_port}/socket/websocket"

    socket_opts =
      [
        cacerts: ca_certs,
        server_name_indication: to_charlist(sni)
      ]
      |> Keyword.put(cert_key, cert_value)
      |> Keyword.put(key_key, key_value)

    default_config = [
      url: url,
      serializer: Jason,
      ssl_verify: :verify_peer,
      transport_opts: [socket_opts: socket_opts]
    ]

    Keyword.merge(default_config, user_config)
  end

  def cert(opts) do
    cond do
      opts[:certfile] != nil -> {:certfile, opts[:certfile]}
      opts[:cert] != nil -> {:cert, opts[:cert]}
      true -> {:cert, Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()}
    end
  end

  def key(opts) do
    cond do
      opts[:keyfile] != nil ->
        {:keyfile, opts[:keyfile]}

      opts[:key] != nil ->
        {:key, opts[:key]}

      true ->
        {:key, {:ECPrivateKey, Nerves.Runtime.KV.get(@key) |> key_pem_to_der()}}
    end
  end

  defp key_pem_to_der(nil), do: <<>>

  defp key_pem_to_der(pem) do
    case X509.PrivateKey.from_pem(pem) do
      {:error, :not_found} -> <<>>
      {:ok, decoded} -> X509.PrivateKey.to_der(decoded)
    end
  end
end
