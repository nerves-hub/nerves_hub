use Mix.Config

config :nerves_hub, NervesHub.API,
  host: "0.0.0.0",
  port: 4002,
  ssl: [
    keyfile: Path.expand("test/fixtures/ssl/user-key.pem"),
    certfile: Path.expand("test/fixtures/ssl/user.pem"),
    cacertfile: Path.expand("test/fixtures/ssl/ca.pem"),
    server_name_indication: 'api.nerves-hub.org'
  ]
