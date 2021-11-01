defmodule Philtre.Articles.CreateArticleTest do
  @moduledoc false

  use Philtre.DataCase

  alias Philtre.Articles

  test "sets slug" do
    assert {:ok, %{slug: "my-article"}} =
             Articles.create_article(%{title: "My Article", body: "Foo"})
  end

  test "requires slug to be unique" do
    assert {:ok, _} = Articles.create_article(%{title: "My Article", body: "Foo"})
    assert {:error, changeset} = Articles.create_article(%{title: "My Article", body: "Foo"})
    assert changeset.errors[:slug]
  end
end
