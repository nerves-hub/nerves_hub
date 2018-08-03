use Mix.Config

config :nerves_hub, NervesHub.API,
  host: "0.0.0.0",
  port: 4002,
  ssl: [
    keyfile: Path.expand("../test/fixtures/ssl/user-key.pem", __DIR__),
    certfile: Path.expand("../test/fixtures/ssl/user.pem", __DIR__),
    cacertfile: Path.expand("../test/fixtures/ssl/ca.pem", __DIR__),
    server_name_indication: 'api.nerves-hub.org'
  ]
