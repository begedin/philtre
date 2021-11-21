defmodule Philtre.Articles.CreateArticleTest do
  @moduledoc false

  use Philtre.DataCase

  alias Philtre.Articles

  @params %Editor.Page{
    blocks: [
      %Editor.Block{
        id: Ecto.UUID.generate(),
        type: "h1",
        content: "My Article"
      },
      %Editor.Block{
        id: Ecto.UUID.generate(),
        type: "p",
        content: "My Content"
      }
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
