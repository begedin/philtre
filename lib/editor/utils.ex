defmodule Editor.Utils do
  @type id :: Ecto.UUID.t()

  @spec new_id :: id
  def new_id do
    Ecto.UUID.generate()
  end
end
