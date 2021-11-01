defmodule Philtre.Articles.Article do
  use Ecto.Schema

  alias Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "articles" do
    field(:title, :string, null: false)
    field(:slug, :string, null: false)
    field(:body, :string, null: false)
  end

  @spec changeset :: Ecto.Changeset.t()
  def changeset do
    changeset(%{})
  end

  @spec changeset(map | t) :: Changeset.t()
  def changeset(%__MODULE__{} = article) do
    changeset(article, %{})
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  @spec changeset(t, map) :: Changeset.t()
  def changeset(%__MODULE__{} = article, %{} = params) do
    article
    |> Changeset.cast(params, [:body, :title])
    |> Changeset.validate_required([:body, :title])
    |> generate_slug()
  end

  defp generate_slug(%Changeset{valid?: false} = changeset), do: changeset

  defp generate_slug(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_change(changeset, :title) do
      :error -> changeset
      {:ok, title} -> Changeset.put_change(changeset, :slug, slugify(title))
    end
  end

  defp slugify(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/[^a-z0-9-\s]/u, "")
    |> String.replace(~r/\s/, "-")
  end
end
