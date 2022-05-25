defmodule Philtre.MixProject do
  use Mix.Project

  def project do
    [
      app: :philtre,
      description: "A block-style editor for live view",
      version: "0.9.3",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
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
      files: [
        "lib",
        "dist",
        "mix.exs",
        ".formatter.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
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
      {:credo, "~> 1.6.0", only: [:dev, :test], runtime: false, optional: true},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28.0", only: :dev, runtime: false},
      {:floki, "~> 0.30.0"},
      {:jason, "~> 1.3.0"},
      {:mix_test_watch, "~> 1.0", only: [:test]},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: [:dev]},
      {:phoenix_live_view, "~> 0.17.0"},
      {:phoenix, "~> 1.6.0"},
      {:plug_cowboy, "~> 2.5.0"},
      {:uuid, "~> 1.1.0"}
    ]
  end

  defp aliases do
    [
      playground: "run --no-halt playground.exs"
    ]
  end
end
