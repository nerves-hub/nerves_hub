# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :nerves_hub, NervesHub.Socket,
  url: "wss://127.0.0.1:4001/socket/websocket",
  serializer: Jason,
  ssl_verify: :verify_peer,
  socket_opts: [
    certfile: Path.expand("../test/fixtures/certs/hub-1234.pem") |> to_charlist,
    keyfile: Path.expand("../test/fixtures/certs/hub-1234-key.pem") |> to_charlist,
    cacertfile: Path.expand("../test/fixtures/certs/ca.pem") |> to_charlist,
    server_name_indication: 'device.nerves-hub.org'
  ]

config :logger, level: :info

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
