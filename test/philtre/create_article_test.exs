defmodule Philtre.Articles.CreateArticleTest do
  @moduledoc false

  use Philtre.DataCase

  alias Philtre.Articles

  test "sets slug" do
    assert {:ok, %{slug: "my-article"}} =
             Articles.create_article(%{title: "My Article", body: "Foo"})
  end
end
