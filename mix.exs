defmodule Algora.MixProject do
  use Mix.Project

  def project do
    [
      app: :algora,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Algora.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:castore, "~> 0.1.13"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_network, "~> 1.3.0"},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_m3u8, "~> 0.9.0"},
      {:exsync, "~> 0.2", only: :dev},
      {:ffmpex, "~> 0.10.0"},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:fly_postgres, "~> 0.3.0"},
      {:gettext, "~> 0.18"},
      {:heroicons, "~> 0.5.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.3.1"},
      {:membrane_core, "~> 1.0"},
      {:membrane_http_adaptive_stream_plugin, "~> 0.18.0"},
      {:membrane_rtmp_plugin, "~> 0.20.0"},
      {:mint, "~> 1.0"},
      {:oban, "~> 2.16"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0", override: true},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:phoenix, "~> 1.7.11"},
      {:plug_cowboy, "~> 2.5"},
      {:swoosh, "~> 1.3"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:thumbnex, "~> 0.5.0"},
      {:timex, "~> 3.0"},
      # ex_aws
      {:ex_aws_s3, "~> 2.3"},
      {:ex_doc, "~> 0.29.0"},
      {:hackney, ">= 0.0.0"},
      {:sweet_xml, ">= 0.0.0", optional: true}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind tv", "esbuild tv"],
      "assets.deploy": [
        "tailwind tv --minify",
        "esbuild tv --minify",
        "phx.digest"
      ]
    ]
  end
end
