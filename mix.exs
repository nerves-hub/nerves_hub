defmodule NervesHub.MixProject do
  use Mix.Project

  Application.put_env(:nerves_hub, :nerves_provisioning, Path.expand("priv/provisioning.conf"))

  def project do
    [
      app: :nerves_hub,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]],
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesHub.Application, []}
    ]
  end

  defp description do
    "The NervesHub client application"
  end

  defp package do
    [
      maintainers: ["Justin Schneck", "Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-hub/nerves_hub"}
    ]
  end

  defp deps do
    [
      {:phoenix_channel_client, "~> 0.3"},
      {:websocket_client, "~> 1.3"},
      {:jason, "~> 1.0"},
      {:hackney, "~> 1.10"},
      {:nerves_runtime, "~> 0.8"},
      {:nerves_hub_cli, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev, :test], runtime: false},
      {:fwup, "~> 0.3.0"}
    ]
  end
end
