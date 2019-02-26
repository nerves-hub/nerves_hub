# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This config.exs file will configure `nerves_hub` to point to a local instance
# of `nerves_hub_web`. See CONTRIBUTING.md for details.

import_config("#{Mix.env()}.exs")
