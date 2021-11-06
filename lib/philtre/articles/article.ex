defmodule Philtre.Articles.Article do
  use Ecto.Schema

  alias Ecto.Changeset

  alias Philtre.Repo

  @type t :: %__MODULE__{}

  schema "articles" do
    field(:title, :string, null: false)
    field(:slug, :string, null: false)
    field(:body, :string, null: false)
    field(:body_html, :string, null: false)
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
    |> generate_html()
    |> generate_slug()
    |> Changeset.unique_constraint(:slug)
    |> Changeset.unsafe_validate_unique(:slug, Repo)
  end

  @spec generate_html(Changeset.t()) :: Changeset.t()
  defp generate_html(%Changeset{valid?: false} = changeset), do: changeset

  defp generate_html(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_change(changeset, :body) do
      :error -> changeset
      {:ok, body} -> Changeset.put_change(changeset, :body_html, to_html(body))
    end
  end

  @spec to_html(String.t()) :: String.t()
  defp to_html(value) when is_binary(value) do
    Earmark.as_html!(value)
  end

  @spec generate_slug(Changeset.t()) :: Changeset.t()
  defp generate_slug(%Changeset{valid?: false} = changeset), do: changeset

  defp generate_slug(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_change(changeset, :title) do
      :error -> changeset
      {:ok, title} -> Changeset.put_change(changeset, :slug, slugify(title))
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
end
