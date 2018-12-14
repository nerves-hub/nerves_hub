defmodule NervesHub.Socket do
  use PhoenixChannelClient.Socket, otp_app: :nerves_hub

  alias NervesHub.Certificate

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"
  @server_name "device.nerves-hub.org"
  @url "wss://" <> @server_name <> "/socket/websocket"

  def opts(nil), do: opts([])

  def opts(user_config) when is_list(user_config) do
    ca_certs = user_config[:cacerts] || Certificate.ca_certs()

    {cert_key, cert_value} = cert(user_config)
    {key_key, key_value} = key(user_config)

    sni = user_config[:server_name_indication] || @server_name
    sni = if is_binary(sni), do: to_charlist(sni), else: sni

    socket_opts =
      [
        cacerts: ca_certs,
        server_name_indication: sni
      ]
      |> Keyword.put(cert_key, cert_value)
      |> Keyword.put(key_key, key_value)

    default_config = [
      url: @url,
      serializer: Jason,
      ssl_verify: :verify_peer,
      socket_opts: socket_opts
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
        key = Nerves.Runtime.KV.get(@key) |> Certificate.pem_to_der()
        {:key, {:ECPrivateKey, key}}
    end
  end
end
