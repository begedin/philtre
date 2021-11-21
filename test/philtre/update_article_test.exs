defmodule Philtre.Articles.UpdateArticleTest do
  @moduledoc false
  use Philtre.DataCase
  alias Philtre.Articles
  alias Philtre.Factories

  @params %Editor.Page{
    blocks: [
      %Editor.Block{
        id: Ecto.UUID.generate(),
        type: "h1",
        content: "My New Title"
      },
      %Editor.Block{
        id: Ecto.UUID.generate(),
        type: "p",
        content: "My New Content"
      }
    ]
  }

  test "sets slug" do
    assert {:ok, %{slug: "my-new-title"}} =
             Factories.create_article() |> Articles.update_article(@params)
  end
end
