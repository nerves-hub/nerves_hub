use Mix.Config

# Configure shoehorn to ignore application failures in dev
config :shoehorn,
  handler: Shoehorn.Handler.Ignore
