use Mix.Config

config :nerves_hub_cli,
  home_dir: Path.expand("nerves-hub"),
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# Shared Configuration.
config :nerves_hub,
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# API HTTP connection.
config :nerves_hub_user_api,
  host: "0.0.0.0",
  port: 4002

# Device HTTP connection.
config :nerves_hub,
  device_api_host: "0.0.0.0",
  device_api_port: 4001

config :nerves_hub,
  client: NervesHub.ClientMock,
  http_client: NervesHub.HTTPClient.Mock,
  rejoin_after: 0

config :nerves_runtime, :kernel, autoload_modules: false
config :nerves_runtime, target: "host"

config :nerves_runtime, :modules, [
  {Nerves.Runtime.KV, Nerves.Runtime.KV.Mock}
]
