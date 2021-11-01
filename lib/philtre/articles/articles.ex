defmodule Philtre.Articles do
  alias Ecto.Changeset
  alias Philtre.Articles
  alias Philtre.Repo

  @spec changeset(map | struct) :: Changeset.t()
  defdelegate changeset(struct_or_params \\ %{}), to: Articles.Article
  @spec changeset(struct, map) :: Changeset.t()
  defdelegate changeset(struct, params), to: Articles.Article

  def create_article(%{} = params) do
    params
    |> Articles.Article.changeset()
    |> Repo.insert()
  end

  def update_article(%Articles.Article{} = article, %{} = params) do
    article
    |> Articles.Article.changeset(params)
    |> Repo.update()
  end

  def list_articles do
    Repo.all(Articles.Article)
  end

  def get_article(id) do
    Repo.get(Articles.Article, id)
  end
end
