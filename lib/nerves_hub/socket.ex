defmodule NervesHub.Socket do
  use PhoenixChannelClient.Socket, otp_app: :nerves_hub

  alias NervesHub.Certificate

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"
  @server_name "device.nerves-hub.org"
  @url "wss://" <> @server_name <> "/socket/websocket"

  def configure(nil), do: configure([])

  def configure(user_config) when is_list(user_config) do
    ca_certs = Certificate.ca_certs()
    cert = Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()
    key = Nerves.Runtime.KV.get(@key) |> Certificate.pem_to_der()

    server_name =
      (user_config[:server_name_indication] || @server_name)
      |> to_charlist()

    default_config = [
      url: @url,
      serializer: Jason,
      ssl_verify: :verify_peer,
      socket_opts: [
        cert: cert,
        key: {:ECPrivateKey, key},
        cacerts: ca_certs,
        server_name_indication: server_name
      ]
    ]

    config = Keyword.merge(default_config, user_config) |> IO.inspect()
    Application.put_env(:nerves_hub, __MODULE__, config)
  end
end
