defmodule Philtre.Articles do
  alias Ecto.Changeset

  alias Philtre.Articles
  alias Philtre.Repo

  def changeset do
    changeset(%{})
  end

  def changeset(%Articles.Article{} = article) do
    changeset(article, %{})
  end

  def changeset(%{} = params) do
    changeset(%Articles.Article{}, params)
  end

  def changeset(%Articles.Article{} = article, %{} = params) do
    article
    |> Changeset.cast(params, [:body, :title])
    |> Changeset.validate_required([:body, :title])
  end

  def create_article(%{} = params) do
    params
    |> changeset()
    |> Repo.insert()
  end

  def update_article(%Articles.Article{} = article, %{} = params) do
    article
    |> changeset(params)
    |> Repo.update()
  end

  def list_articles do
    Repo.all(Articles.Article)
  end

  def get_article(id) do
    Repo.get(Articles.Article, id)
  end
end
