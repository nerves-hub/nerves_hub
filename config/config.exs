# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This config.exs file will configure `nerves_hub` to point to a local instance
# of `nerves_hub_web`. See CONTRIBUTING.md for details.

config :nerves_hub_cli,
  home_dir: Path.expand("nerves-hub"),
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# API HTTP connection.
config :nerves_hub_cli, NervesHubCLI.API,
  host: "0.0.0.0",
  port: 4002

# Device Websocket/Channel connection.
config :nerves_hub, NervesHub.Socket, url: "wss://0.0.0.0:4001/socket/websocket"

# Device HTTP connection.
config :nerves_hub, NervesHub.HTTPClient,
  host: "0.0.0.0",
  port: 4001

# Shared Configuration.
config :nerves_hub,
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# nerves_runtime needs to disable
# and mock out some parts.

cert =
  if File.exists?("./nerves-hub/test-cert.pem"),
    do: File.read!("./nerves-hub/test-cert.pem")

key =
  if File.exists?("./nerves-hub/test-key.pem"),
    do: File.read!("./nerves-hub/test-key.pem")

config :nerves_runtime, Nerves.Runtime.KV.Mock, %{
  "nerves_fw_active" => "a",
  "a.nerves_fw_uuid" => "f735d7e2-c16c-42bb-8e5c-700b384b7f12",
  "nerves_hub_cert" => cert,
  "nerves_hub_key" => key,
  "nerves_fw_devpath" => "/no!"
}

config :nerves_runtime, :modules, [
  {Nerves.Runtime.KV, Nerves.Runtime.KV.Mock}
]

config :nerves_runtime, :kernel, autoload_modules: false

config :nerves_runtime, target: "host"
