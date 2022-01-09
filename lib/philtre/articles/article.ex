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

  @spec changeset(Editor.Page.t()) :: Changeset.t()
  def changeset(%Editor.Page{} = page) do
    changeset(%__MODULE__{}, page)
  end

  @spec changeset(t, Editor.Page.t()) :: Changeset.t()
  def changeset(%__MODULE__{} = article, %Editor.Page{} = page) do
    article
    |> Changeset.cast(
      %{content: Editor.serialize(page), slug: slug(page)},
      [:content, :slug]
    )
    |> Changeset.unique_constraint(:slug)
    |> Changeset.unsafe_validate_unique(:slug, Repo)
  end

  def title(%__MODULE__{} = article) do
    article.content
    |> Editor.normalize()
    |> title()
  end

  def title(%Editor.Page{blocks: blocks}) do
    blocks
    |> Enum.at(0)
    |> Editor.text()
  end

  def slug(%__MODULE__{} = article) do
    article
    |> title()
    |> slugify()
  end

  def slug(%Editor.Page{} = page) do
    page
    |> title()
    |> slugify()
  end

  def body(%__MODULE__{} = article) do
    article.content
    |> Editor.normalize()
    |> body()
  end

  def body(%Editor.Page{blocks: [_heading | rest]}) do
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
