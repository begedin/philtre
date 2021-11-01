defmodule Philtre.Factories do
  @moduledoc """
  Contains test factories
  """
  alias Philtre.Articles

  @article_params %{title: "My Article", body: "Lorem ipsum"}

  @spec create_article(map) :: Articles.Article.t()
  def create_article(params \\ @article_params) do
    {:ok, article} = Articles.create_article(params)
    article
  end

  @spec create_articles(list(map)) :: list(Articles.Article.t())
  def create_articles(params) when is_list(params) do
    Enum.map(params, &create_article/1)
  end

  @spec create_articles(pos_integer, map) :: list(Articles.Article.t())
  def create_articles(count, %{} = params \\ %{}) when is_integer(count) and count > 1 do
    Enum.map(1..count, fn index ->
      @article_params
      |> Map.merge(params)
      |> Enum.map(fn {k, v} -> {k, "#{v} #{index}"} end)
      |> Map.new()
      |> create_article()
    end)
  end
end
