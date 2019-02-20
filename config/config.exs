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

config :nerves_runtime, :kernel, autoload_modules: false

config :nerves_runtime, target: "host"

import_config("#{Mix.env()}.exs")
