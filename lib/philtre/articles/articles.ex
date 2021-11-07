defmodule Philtre.Articles do
  @moduledoc """
  Primary context for dealing with articles.

  An article is a single blogpost published on the site.
  """
  alias Ecto.Changeset
  alias Philtre.Articles
  alias Philtre.Repo

  @spec changeset(map | struct) :: Changeset.t()
  defdelegate changeset(struct_or_params \\ %{}), to: Articles.Article
  @spec changeset(struct, map) :: Changeset.t()
  defdelegate changeset(struct, params), to: Articles.Article

  @spec create_article(map) :: {:ok, Articles.Article.t()} | {:error, Changeset.t()}
  def create_article(%{} = params) do
    params
    |> Articles.Article.changeset()
    |> Repo.insert()
  end

  @spec update_article(Articles.Article.t(), map) ::
          {:ok, Articles.Article.t()} | {:error, Changeset.t()}
  def update_article(%Articles.Article{} = article, %{} = params) do
    article
    |> Articles.Article.changeset(params)
    |> Repo.update()
  end

  @spec list_articles :: list(Articles.Article.t())
  def list_articles do
    Repo.all(Articles.Article)
  end

  @spec get_article(String.t()) :: {:ok, Articles.Article.t()} | {:error, :not_found}
  def get_article(slug) do
    case Repo.get_by(Articles.Article, slug: slug) do
      %Articles.Article{} = article -> {:ok, article}
      nil -> {:error, :not_found}
    end
  end
end
