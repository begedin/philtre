defmodule Philtre.Factories do
  @moduledoc """
  Contains test factories
  """
  alias Philtre.Articles

  @spec create_article :: Articles.Article.t()
  def create_article do
    {:ok, article} = Articles.create_article(%{title: "My Article", body: "Lorem ipsum"})
    article
  end
end
