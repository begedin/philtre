defmodule Philtre.StaticBlock do
  @moduledoc """
  Static component used to render any type of block.

  Works in similar fashion to `Philtre.LiveBlock`, but in a simplified capacity.
  """

  def render(%{block: %module{}} = assigns) do
    module.render_static(assigns)
  end
end
