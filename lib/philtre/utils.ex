defmodule Philtre.Editor.Utils do
  @moduledoc """
  Contains various utility functions used by the library, that don't really have
  another place to fit in.
  """
  @type id :: String.t()

  @spec new_id :: id
  def new_id do
    UUID.uuid4()
  end

  def selection_start, do: ~s(<span data-selection-start></span>)
  def selection_end, do: ~s(<span data-selection-end></span>)
end
