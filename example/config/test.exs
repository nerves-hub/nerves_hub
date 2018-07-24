use Mix.Config

# Configure shoehorn to ignore application failures in test
config :shoehorn,
  handler: Shoehorn.Handler.Ignore
