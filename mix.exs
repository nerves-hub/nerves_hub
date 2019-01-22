defmodule NervesHub.MixProject do
  use Mix.Project

  Application.put_env(:nerves_hub, :nerves_provisioning, Path.expand("priv/provisioning.conf"))

  def project do
    [
      app: :nerves_hub,
      deps: deps(),
      description: description(),
      docs: [main: "readme", extras: ["README.md"]],
      dialyzer: [plt_add_apps: [:nerves_key, :nerves_key_pkcs11, :atecc508a]],
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: "0.3.0"
    ]
  end

  def application do
    [
      env: [
        client: NervesHub.Client.Default,
        device_host: "device.nerves-hub.org",
        device_port: 443,
        rejoin_after: 5_000,
        fwup_public_keys: [],
        cacerts: nil,
        http_client: NervesHub.HTTPClient.Default,
        runtime: NervesHub.Runtime.NervesKV
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]

  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "The NervesHub client application"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-hub/nerves_hub"}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:fwup, "~> 0.3.0"},
      {:hackney, "~> 1.10"},
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:mox, "~> 0.4", only: :test},
      {:nerves_key, "~> 0.3", optional: true},
      {:nerves_key_pkcs11, "~> 0.1", optional: true},
      {:nerves_hub_cli, "~> 0.6.0", runtime: false},
      {:nerves_runtime, "~> 0.8"},
      {:phoenix_channel_client, "~> 0.4"},
      {:websocket_client, "~> 1.3"},
      {:x509, "~> 0.5"}
    ]
  end
end

Enum.each(NervesHub.MixProject.application()[:env], fn {k, v} ->
  Application.put_env(:nerves_hub, k, v)
end)
