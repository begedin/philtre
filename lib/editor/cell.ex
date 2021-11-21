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

  def trim(%__MODULE__{content: "# " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "## " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "### " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "#&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "##&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "###&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "```" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "* " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "*&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: content} = cell), do: %{cell | content: content}

  def transform(%__MODULE__{} = cell, type) when type in ["li"] do
    %{cell | type: type}
  end

  def backspace(%__MODULE__{content: ""}), do: :delete
  def backspace(%__MODULE__{}), do: :join_to_previous

  def join(%__MODULE__{} = from, %__MODULE__{} = to) do
    %{to | content: to.content <> from.content}
  end
end
