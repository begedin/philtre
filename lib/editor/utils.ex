defmodule Editor.Utils do
  @moduledoc """
  Contains various utility functions used by the library, that don't really have
  another place to fit in.
  """
  @type id :: Ecto.UUID.t()

  @spec new_id :: id
  def new_id do
    Ecto.UUID.generate()
  end
end