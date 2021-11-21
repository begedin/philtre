defmodule Editor.Cell do
  defstruct [:id, :type, :content]

  def new() do
    %__MODULE__{
      id: Editor.Utils.new_id(),
      type: "span",
      content: ""
    }
  end

  def split(%__MODULE__{} = cell, index) do
    {content_before, content_after} = String.split_at(cell.content, index)
    cell_before = %{cell | content: content_before}

    cell_after = %{
      cell
      | content: content_after,
        id: Editor.Utils.new_id()
    }

    {cell_before, cell_after}
  end
end
