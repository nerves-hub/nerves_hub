# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This config.exs file will configure `nerves_hub` to point to a local instance
# of `nerves_hub_web`. See CONTRIBUTING.md for details.

config :nerves_hub_cli,
  home_dir: Path.expand("nerves-hub"),
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# API HTTP connection.
config :nerves_hub_core,
  api_host: "0.0.0.0",
  api_port: 4002

# Device HTTP connection.
config :nerves_hub,
  device_api_host: "0.0.0.0",
  device_api_port: 4001

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
  "a.nerves_fw_uuid" => "8a8b902c-d1a9-58aa-6111-04ab57c2f2a8",
  "nerves_hub_cert" => cert,
  "nerves_hub_key" => key,
  "nerves_fw_devpath" => "/no!"
}

config :nerves_runtime, :modules, [
  {Nerves.Runtime.KV, Nerves.Runtime.KV.Mock}
]

config :nerves_runtime, :kernel, autoload_modules: false

config :nerves_runtime, target: "host"

case Mix.env() do
  :dev ->
    config :mix_test_watch,
      clear: true

  :test ->
    config :nerves_hub,
      client: NervesHub.ClientMock,
      http_client: NervesHub.HTTPClient.Mock,
      rejoin_after: 0

  :prod ->
    :ok
end
