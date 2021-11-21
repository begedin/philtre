defmodule Philtre.Articles.Article do
  @moduledoc """
  Represents a single blog article stored in the database.

  The `:slug` field is produced automatically as the user is editing the
  `:title` field.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  alias Philtre.Repo

  defmodule Section do
    @moduledoc """
    Represents a section of an article
    """
    use Ecto.Schema
    alias Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:content, :string, null: false)
      field(:id, :binary_id, null: false, primary_key: true, autogenerate: true)
      field(:type, :string, null: false)
    end

    def changeset(struct, params) do
      struct
      |> Changeset.cast(params, [:content, :id, :type])
      |> Changeset.validate_required([:content, :id, :type])
      |> Changeset.validate_inclusion(:type, ["h1", "h2", "h3", "p", "pre"])
    end
  end

  @type t :: %__MODULE__{}

  schema "articles" do
    field(:slug, :string, null: false)
    embeds_many(:sections, Section, on_replace: :delete)
  end

  @spec changeset(Editor.Page.t()) :: Changeset.t()
  def changeset(%Editor.Page{} = page) do
    params = from_page(page)
    changeset(%__MODULE__{}, params)
  end

  @spec changeset(t, Editor.Page.t() | map) :: Changeset.t()
  def changeset(%__MODULE__{} = article, %Editor.Page{} = page) do
    params = from_page(page)
    changeset(article, params)
  end

  def changeset(%__MODULE__{} = article, %{} = params) do
    article
    |> Changeset.cast(params, [])
    |> Changeset.cast_embed(:sections, required: true)
    |> generate_slug()
    |> Changeset.unique_constraint(:slug)
    |> Changeset.unsafe_validate_unique(:slug, Repo)
  end

  @spec generate_slug(Changeset.t()) :: Changeset.t()
  defp generate_slug(%Changeset{valid?: false} = changeset), do: changeset

  defp generate_slug(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_field(changeset, :sections) do
      :error ->
        changeset

      {_, [%Changeset{} = section_changeset | _]} ->
        title = Changeset.fetch_field!(section_changeset, :content)
        Changeset.put_change(changeset, :slug, slugify(title))

      {_, [%Section{} = section | _]} ->
        title = section.content
        Changeset.put_change(changeset, :slug, slugify(title))
    end
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

  @spec to_page(t) :: Editor.Page.t()
  def to_page(%__MODULE__{} = article) do
    %Editor.Page{
      blocks:
        Enum.map(article.sections, fn %Section{} = section ->
          %Editor.Block{id: section.id, content: section.content, type: section.type}
        end)
    }
  end

  @spec from_page(Editor.Page.t()) :: map
  def from_page(%Editor.Page{} = page) do
    %{
      sections:
        Enum.map(page.blocks, fn %Editor.Block{} = block ->
          Map.from_struct(%Section{id: block.id, content: block.content, type: block.type})
        end)
    }
  end
end
