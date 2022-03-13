defmodule Philtre.Articles.CreateArticleTest do
  @moduledoc false

  use Philtre.DataCase

  alias Editor.Block
  alias Philtre.Articles

  @params %Editor{
    blocks: [
      %Block.H1{id: "1", pre_caret: "My Article"},
      %Block.P{id: "2", pre_caret: "My Content"}
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
