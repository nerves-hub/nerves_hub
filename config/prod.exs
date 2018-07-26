use Mix.Config

config :nerves_hub, NervesHub.API,
  host: "api.nerves-hub.org",
  port: 443,
  ssl: [
    keyfile: Path.expand("~/.nerves-hub/user-key.pem"),
    certfile: Path.expand("~/.nerves-hub/user.pem"),
    cacertfile: Path.expand("~/.nerves-hub/ca.pem"),
    server_name_indication: 'api.nerves-hub.org'
  ]
