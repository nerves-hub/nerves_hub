use Mix.Config

config :nerves_hub,
  client: NervesHub.ClientMock,
  http_client: NervesHub.HTTPClient.Mock,
  rejoin_after: 0
