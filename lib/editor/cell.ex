defmodule Editor.Cell do
  @moduledoc """
  Represents a single atomic component of a block of a page.

  Theese tend to change most dynamically. They get split, shuffled around,
  removed, or updated as the user does things.
  """
  defstruct [:id, :type, :content]

  @type t :: %__MODULE__{}
  @type id :: String.t()

  @spec new(String.t(), String.t()) :: t
  def new(type \\ "span", content \\ "") do
    %__MODULE__{
      id: Editor.Utils.new_id(),
      type: type,
      content: content
    }
  end

  @doc """
  Removes "markdownlike" code from a cell's content
  """
  @spec trim(t) :: t
  def trim(%__MODULE__{content: "# " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "## " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "### " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "#&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "##&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "###&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "```" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "* " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "*&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "&gt; " <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: "&gt;&nbsp;" <> rest} = cell), do: %{cell | content: rest}
  def trim(%__MODULE__{content: content} = cell), do: %{cell | content: content}

  @doc """
  Transforms cell into the specified type
  """
  @spec transform(t, String.t()) :: t
  def transform(%__MODULE__{} = cell, type) when type in ["span", "li"] do
    %{cell | type: type}
  end

  @doc """
  Resolves the result of a backspace operation on a cell

  The cell will either be deleted, or be joined with the previous cell
  """
  @spec backspace(t) :: :delete | :join_to_previous
  def backspace(%__MODULE__{content: ""}), do: :delete
  def backspace(%__MODULE__{}), do: :join_to_previous

  @doc """
  Joins the content of the first cell into the second
  """
  @spec join(t, t) :: t
  def join(%__MODULE__{} = from, %__MODULE__{} = to) do
    %{to | content: to.content <> from.content}
  end

  @doc """
  Clones the cell by giving it a new id
  """
  @spec clone(t) :: t
  def clone(%__MODULE__{} = cell) do
    %{cell | id: Editor.Utils.new_id()}
  end
end
