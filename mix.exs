defmodule Philtre.MixProject do
  use Mix.Project

  def project do
    [
      app: :philtre,
      description: "A block-style editor for live view",
      version: "0.9.2",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["Nikola Begedin"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/philtre/changelog.html",
        GitHub: "https://github.com/begedin/philtre"
      }
    ]
  end

  def application do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "playground", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "playground"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~>1.6.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:floki, ">= 0.30.0"},
      {:jason, "~> 1.2"},
      {:mix_test_watch, "~> 1.0", only: [:test]},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: [:dev]},
      {:phoenix_live_view, "~> 0.17.6"},
      {:phoenix, "~> 1.6.8"},
      {:plug_cowboy, "~> 2.5"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      playground: "run --no-halt playground.exs"
    ]
  end
end
