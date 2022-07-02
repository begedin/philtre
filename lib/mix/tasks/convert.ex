defmodule Mix.Tasks.Convert do
  @moduledoc """
  Handles conversion of old block formats to newer
  """
  use Mix.Task

  alias Philtre.Block.Code
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.Table
  alias Philtre.Editor
  alias Philtre.Editor.Serializer

  def run([path]) do
    path = Path.join(File.cwd!(), path)
    files = File.ls!(path)

    paths = Enum.map(files, &Path.join(path, &1))

    paths
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.each(fn file ->
      converted =
        file
        |> File.read!()
        |> Jason.decode!()
        |> normalize()
        |> Serializer.serialize()
        |> Jason.encode!(pretty: true)

      File.write!(file, converted)
    end)
  end

  @types [
    "p",
    "h1",
    "h2",
    "h3",
    "blockquote",
    "pre",
    "li"
  ]

  def normalize(%{"id" => id, "blocks" => blocks}) when is_binary(id) and is_list(blocks) do
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"blocks" => blocks} = params) when is_list(blocks) do
    params |> Map.put("id", Editor.Utils.new_id()) |> normalize()
  end

  def normalize(%{"id" => id, "type" => kind, "content" => content})
      when kind in @types and is_list(content) do
    %ContentEditable{id: id, kind: kind, cells: Enum.map(content, &normalize/1)}
  end

  def normalize(%{"id" => id, "modifiers" => modifiers, "text" => text}) do
    %ContentEditable.Cell{id: id, modifiers: modifiers, text: text}
  end

  def normalize(%{"id" => id, "type" => "table"} = data) do
    %Table{
      id: id,
      rows: Map.get(data, "rows", []),
      header_rows: Map.get(data, "header_rows", [])
    }
  end

  def normalize(%{"id" => id, "content" => content, "language" => language, "type" => "code"}) do
    %Code{id: id, content: content, language: language}
  end

  def normalize(content) do
    Serializer.normalize(content)
  end
end
