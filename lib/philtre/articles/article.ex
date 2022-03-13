defmodule Philtre.Articles.Article do
  @moduledoc """
  Represents a single blog article stored in the database.

  The `:slug` field is produced automatically as the user is editing the
  `:title` field.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  alias Philtre.Repo

  @type t :: %__MODULE__{}

  schema "articles" do
    field(:slug, :string, null: false)
    field(:content, :map)
  end

  @spec changeset(Editor.t()) :: Changeset.t()
  def changeset(%Editor{} = editor) do
    changeset(%__MODULE__{}, editor)
  end

  @spec changeset(t, Editor.t()) :: Changeset.t()
  def changeset(%__MODULE__{} = article, %Editor{} = editor) do
    content = Editor.serialize(editor)

    article
    |> Changeset.cast(%{content: content, slug: slug(editor)}, [:content, :slug])
    |> Changeset.unique_constraint(:slug)
    |> Changeset.unsafe_validate_unique(:slug, Repo)
  end

  def title(%__MODULE__{} = article) do
    article.content
    |> Editor.normalize()
    |> title()
  end

  def title(%Editor{blocks: blocks}) do
    blocks
    |> Enum.at(0)
    |> Editor.text()
  end

  def slug(%__MODULE__{} = article) do
    article
    |> title()
    |> slugify()
  end

  def slug(%Editor{} = editor) do
    editor
    |> title()
    |> slugify()
  end

  def body(%__MODULE__{} = article) do
    article.content
    |> Editor.normalize()
    |> body()
  end

  def body(%Editor{blocks: [_heading | rest]}) do
    Enum.map_join(rest, &Editor.text/1)
  end

  @spec slugify(String.t()) :: String.t()
  defp slugify(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/[^a-z0-9-\s]/u, "")
    |> String.replace(~r/\s/, "-")
  end
end
