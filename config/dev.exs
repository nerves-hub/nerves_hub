use Mix.Config

## Local NervesHub config.

# Configure the CLI to use a local instance.
config :nerves_hub_cli, NervesHubCLI.API,
  host: "0.0.0.0",
  port: 4002

# Configure the CLI to use local fixtures.
config :nerves_hub_cli,
  home: Path.expand("../nerves-hub", __DIR__),
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__)

# Configure the socket to use a local instance.
config :nerves_hub, NervesHub.Socket, url: "wss://0.0.0.0:4001/socket/websocket"

# Configure NervesHub to use the TestIdentifier.
config :nerves_hub,
  ca_certs: Path.expand("../test/fixtures/ca_certs", __DIR__),
  identifier: NervesHub.TestIdentifier

test_uuid = "test"

# A chicken and egg problem here.
# We can only use the keys if they exist.
# This requires developers to do
#   mix nerves_hub device create
# before compileing this application to generate certs.

cert =
  case File.read(Path.expand("../nerves-hub/#{test_uuid}-cert.pem", __DIR__)) do
    {:ok, pem} -> pem
    _ -> nil
  end

key =
  case File.read(Path.expand("../nerves-hub/#{test_uuid}-key.pem", __DIR__)) do
    {:ok, pem} -> pem
    _ -> nil
  end

config :nerves_hub, NervesHub.TestIdentifier,
  # We only want to set the uuid if a cert and key exist.
  uuid: cert && key && test_uuid,
  cert: cert,
  key: key
