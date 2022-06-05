defmodule Philtre.MixProject do
  use Mix.Project

  @source_url "https://github.com/begedin/philtre"
  @version "0.10.1"

  def project do
    [
      app: :philtre,
      description: "A block-style editor for live view",
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],
      package: package(),
      docs: docs(),
      source_url: @source_url
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
      {:floki, "~> 0.30"},
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

  def docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      source_ref: @version,
      source_url: @source_url,
      groups_for_modules: [
        General: [
          Philtre.Editor,
          Philtre.Editor.Engine,
          Philtre.Editor.Serializer,
          Philtre.Editor.Utils,
          Philtre.UI.Page
        ],
        Blocks: [
          Philtre.Block.Code,
          Philtre.Block.Table,
          Philtre.Block.ContentEditable
        ],
        ContentEditable: [
          Philtre.Block.ContentEditable.Cell,
          Philtre.Block.ContentEditable.CleanEmptyCells,
          Philtre.Block.ContentEditable.Reduce,
          Philtre.Block.ContentEditable.Selection
        ],
        Playground: [
          Playground.App,
          Playground.Controller,
          Playground.Documents,
          Playground.Endpoint,
          Playground.Live.Edit,
          Playground.Live.Index,
          Playground.Live.New,
          Playground.Router,
          Playground.Router.Helpers,
          Playground.View
        ]
      ]
    ]
  end

  defp aliases do
    [
      playground: "run --no-halt -e 'Playground.App.run()'"
    ]
  end
end
