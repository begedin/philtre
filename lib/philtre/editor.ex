defmodule Philtre.Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """

  alias Philtre.Editor.Block
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
        %Block{
          id: Utils.new_id(),
          cells: [
            %Block.Cell{id: Utils.new_id(), text: "This is the title of your page", modifiers: []}
          ],
          selection: %Block.Selection{},
          type: "h1"
        },
        %Block{
          id: Utils.new_id(),
          cells: [
            %Block.Cell{id: Utils.new_id(), text: "This is your first paragraph.", modifiers: []}
          ],
          selection: %Block.Selection{},
          type: "p"
        }
      ]
    }
  end

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer
end
