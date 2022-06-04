defmodule Philtre.Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """

  alias Philtre.Block.ContentEditable
  alias Philtre.Editor.Serializer
  alias Philtre.Editor.Utils

  defstruct blocks: [],
            clipboard: nil,
            id: nil,
            selected_blocks: [],
            selection: nil

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{
      id: Utils.new_id(),
      blocks: [
        %ContentEditable{
          id: Utils.new_id(),
          cells: [
            %ContentEditable.Cell{
              id: Utils.new_id(),
              text: "This is the title of your page",
              modifiers: []
            }
          ],
          selection: %ContentEditable.Selection{},
          type: "h1"
        },
        %ContentEditable{
          id: Utils.new_id(),
          cells: [
            %ContentEditable.Cell{
              id: Utils.new_id(),
              text: "This is your first paragraph.",
              modifiers: []
            }
          ],
          selection: %ContentEditable.Selection{},
          type: "p"
        }
        # Uncomment to test table
        # %Philtre.Block.Table{
        #   id: Utils.new_id(),
        #   header_rows: [
        #     ["a", "header", "column"]
        #   ],
        #   rows: [
        #     ["a", "row", ""],
        #     ["another", "row", ""],
        #     ["yet", "another", "row"]
        #   ]
        # },
        # Uncomment to test code
        # %Philtre.Block.Code{
        #   id: Utils.new_id(),
        #   language: "elixir",
        #   content: "defmodule Foo do"
        # }
      ]
    }
  end

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer

  @spec replace_block(t(), struct(), list(struct)) :: t()
  def replace_block(%__MODULE__{} = editor, %{id: _id} = block, new_blocks)
      when is_list(new_blocks) do
    case Enum.find_index(editor.blocks, &(&1.id === block.id)) do
      nil ->
        editor

      index when is_integer(index) ->
        new_blocks =
          editor.blocks
          |> List.replace_at(index, new_blocks)
          |> List.flatten()

        %{editor | blocks: new_blocks}
    end
  end
end
