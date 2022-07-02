defmodule Playground.Documents do
  @moduledoc """
  Main context for storing editor content onto disk as json
  """
  @folder Path.join("playground/priv", "documents")

  alias Philtre.Editor

  defp file_path(filename) do
    Path.join(@folder, filename)
  end

  defp ensure_json(filename) do
    if String.ends_with?(filename, ".json") do
      filename
    else
      filename <> ".json"
    end
  end

  def list_documents do
    @folder |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".json"))
  end

  def get_document(filename) when is_binary(filename) do
    case filename |> ensure_json() |> file_path() |> File.read() do
      {:ok, json} -> {:ok, json |> Jason.decode!() |> Editor.normalize()}
      {:error, _} -> {:error, :not_found}
    end
  end

  def save_document(%Editor{} = editor, filename) when is_binary(filename) do
    json = editor |> Editor.serialize() |> Jason.encode!(pretty: true)
    filename |> ensure_json() |> file_path() |> File.write!(json)
  end

  def delete_document(filename) when is_binary(filename) do
    filename |> ensure_json() |> file_path() |> File.rm!()
  end
end
