defmodule Philtre.Articles.UpdateArticleTest do
  @moduledoc false
  use Philtre.DataCase
  alias Philtre.Articles
  alias Philtre.Factories

  @params %Editor{
    blocks: [
      %Editor.Block{
        id: Editor.Utils.new_id(),
        type: "h1",
        cells: [%Editor.Cell{type: "span", content: "My New Title"}]
      },
      %Editor.Block{
        id: Editor.Utils.new_id(),
        type: "p",
        cells: [%Editor.Cell{type: "span", content: "My New Content"}]
      }
    ]
  }

  test "sets slug" do
    assert {:ok, %{slug: "my-new-title"}} =
             Factories.create_article() |> Articles.update_article(@params)
  end
end
