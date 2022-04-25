defmodule Philtre.MixProject do
  use Mix.Project

  def project do
    [
      app: :philtre,
      version: "0.8.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~>1.6.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0"},
      {:jason, "~> 1.2"},
      {:mix_test_watch, "~> 1.0", only: [:test]},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.17.6"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm --prefix assets install"],
      "assets.deploy": ["cmd npm --prefix assets run deploy"],
      "test.e2e": ["cmd mix phx.server & npm --prefix assets run test:e2e"],
      "test.e2e.ci": ["cmd mix phx.server & npm --prefix assets run test:e2e:ci"],
      test: ["test", "cmd cd playground && mix test"],
      "deps.get": ["deps.get", "cmd cd playground && mix deps.get"]
    ]
  end
end
