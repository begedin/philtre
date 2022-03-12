defmodule Philtre.Articles.UpdateArticleTest do
  @moduledoc false
  use Philtre.DataCase

  alias Editor.Block
  alias Philtre.Articles
  alias Philtre.Factories

  @params %Editor{
    blocks: [
      %Block.H1{id: Editor.Utils.new_id(), pre_caret: "My New title"},
      %Block.P{id: Editor.Utils.new_id(), pre_caret: "Bar"}
    ]
  }

  test "sets slug" do
    assert {:ok, %{slug: "my-new-title"}} =
             Factories.create_article() |> Articles.update_article(@params)
  end
end
