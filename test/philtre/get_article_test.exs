defmodule Philtre.Articles.GetArticleTest do
  @moduledoc false
  use Philtre.DataCase
  alias Philtre.Articles
  alias Philtre.Factories

  test "retrieves article by slug" do
    article = Factories.create_article()
    assert {:ok, _} = Articles.get_article(article.slug)
  end

  test "returns error tuple if not found" do
    assert {:error, :not_found} = Articles.get_article("foo")
  end
end
