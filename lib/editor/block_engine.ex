defmodule Editor.BlockEngine do
  alias Editor.Utils
  alias Editor.Block

  def update(%_{pre_caret: _, post_caret: _} = block, pre_caret, post_caret) do
    %{
      block
      | active: true,
        pre_caret: pre_caret,
        post_caret: post_caret
    }
  end

  def split_line(%_{pre_caret: _, post_caret: _} = block, pre_caret, post_caret) do
    %{
      block
      | active: true,
        pre_caret: pre_caret <> "<br />",
        post_caret: post_caret
    }
  end

  def split_block(%_{pre_caret: _, post_caret: _} = block, pre_caret, post_caret) do
    old_block = %{block | active: false, pre_caret: pre_caret, post_caret: ""}

    new_block = %Block.P{
      id: Utils.new_id(),
      active: true,
      pre_caret: "",
      post_caret: post_caret
    }

    [old_block, new_block]
  end

  def convert(%_{pre_caret: _, post_caret: _} = block, pre_caret, post_caret, Block.P) do
    %Block.P{
      id: Utils.new_id(),
      active: block.active,
      pre_caret: pre_caret,
      post_caret: post_caret
    }
  end

  def merge(%{} = self, %Block.P{} = other) do
    %{
      self
      | active: true,
        pre_caret: self.pre_caret <> self.post_caret,
        post_caret: other.pre_caret <> other.post_caret
    }
  end
end
