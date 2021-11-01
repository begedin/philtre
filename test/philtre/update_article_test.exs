defmodule Philtre.Articles.UpdateArticleTest do
  @moduledoc false
  use Philtre.DataCase
  alias Philtre.Articles
  alias Philtre.Factories

  test "sets slug" do
    assert {:ok, %{slug: "my-article-2"}} =
             Factories.create_article()
             |> Articles.update_article(%{title: "My Article 2", body: "Foo"})
  end
end
