defmodule Philtre.Articles.CreateArticleTest do
  @moduledoc false

  use Philtre.DataCase

  alias Editor.Block
  alias Philtre.Articles

  @params %Editor{
    blocks: [
      %Block{id: "1", pre_caret: "My Article", type: "h1"},
      %Block{id: "2", pre_caret: "My Content", type: "p"}
    ]
  }
  test "sets slug" do
    assert {:ok, %{slug: "my-article"}} = Articles.create_article(@params)
  end

  test "requires slug to be unique" do
    assert {:ok, _} = Articles.create_article(@params)
    assert {:error, changeset} = Articles.create_article(@params)
    assert changeset.errors[:slug]
  end
end
