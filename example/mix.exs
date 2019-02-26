defmodule Example.MixProject do
  use Mix.Project

  @all_targets [:rpi, :rpi2, :rpi3, :rpi3a, :rpi0, :bbb, :x86_64]

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.8",
      archives: [nerves_bootstrap: "~> 1.0"],
      start_permanent: Mix.env() == :prod,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Example.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.4", runtime: false},
      {:shoehorn, "~> 0.4"},
      {:nerves_hub, path: "../"},
      {:nerves_runtime, "~> 0.8"},

      {:nerves_init_gadget, "~> 0.5", targets: @all_targets},
      {:nerves_time, "~> 0.2", targets: @all_targets},

      {:nerves_system_rpi, "~> 1.6", targets: :rpi, runtime: false},
      {:nerves_system_rpi0, "~> 1.6", targets: :rpi0, runtime: false},
      {:nerves_system_rpi2, "~> 1.6", targets: :rpi2, runtime: false},
      {:nerves_system_rpi3, "~> 1.6", targets: :rpi3, runtime: false},
      {:nerves_system_rpi3a, "~> 1.6", targets: :rpi3a, runtime: false},
      {:nerves_system_bbb, "~> 2.1", targets: :bbb, runtime: false},
      {:nerves_system_x86_64, "~> 1.6", targets: :x86_64, runtime: false},
    ]
  end
end
