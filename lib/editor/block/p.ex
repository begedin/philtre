defmodule Editor.Block.P do
  @moduledoc """
  Holds logic specific to the p block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  use Editor.ReactiveComponent,
    events: ["split", "update", "transform", "merge_previous"]

  alias Editor.Block
  alias Editor.Utils

  # struct

  defstruct [:content, :id]

  @type t :: %__MODULE__{}

  # component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <p
      contenteditable
      phx-hook="ContentEditable"
      phx-target={@myself}
      phx-debounce={500}
      id={@block.id}
    ><%= raw(@block.content) %></p>
    """
  end

  def handle_event("update", %{"value" => new_content}, socket) do
    new_content = cleanup(new_content)
    old_block = socket.assigns.block

    new_block =
      case transform_type(new_content) do
        nil -> %{old_block | content: new_content}
        other -> transform(%{old_block | content: new_content}, other)
      end

    emit(socket, "update", %{block: new_block})

    {:noreply, socket}
  end

  def handle_event("split_line", %{"pre" => pre_content, "post" => post_content}, socket) do
    %__MODULE__{} = block = socket.assigns.block

    %__MODULE__{} = new_block = %{block | content: pre_content <> "<br/>" <> post_content}

    emit(socket, "replace", %{block: block, with: new_block})
    {:noreply, socket}
  end

  def handle_event("split_block", %{"pre" => pre_content, "post" => post_content}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | content: pre_content}
    new_block = %__MODULE__{id: Utils.new_id(), content: post_content}
    emit(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    emit(socket, "merge_previous", %{block: socket.assigns.block})
    {:noreply, socket}
  end

  # api

  @spec serialize(t) :: map
  def serialize(%__MODULE__{id: id, content: content}) do
    %{"id" => id, "type" => "p", "content" => content}
  end

  @spec normalize(map) :: t
  def normalize(%{"id" => id, "type" => "p", "content" => content}) do
    %__MODULE__{
      id: id,
      content: content
    }
  end

  def html(%__MODULE__{content: content}), do: "<p>#{content}</p>"

  defp cleanup(content) do
    content
    |> String.replace("&nbsp;", " ", global: true)
    |> String.replace("&gt;", ">", global: true)
  end

  defp transform_type("# " <> _), do: Block.H1
  defp transform_type("## " <> _), do: Block.H2
  defp transform_type("### " <> _), do: Block.H3
  defp transform_type("* " <> _), do: Block.Li
  defp transform_type("```" <> _), do: Block.Pre
  defp transform_type("> " <> _), do: Block.Blockquote
  defp transform_type("&gt; " <> _), do: Block.Blockquote
  defp transform_type(_), do: nil

  def text(%__MODULE__{content: content}) do
    content |> Floki.parse_document!() |> Floki.text()
  end

  def merge(%__MODULE__{content: content} = this, %__MODULE__{content: other_content}) do
    %{this | content: content <> other_content}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.H1) do
    %Block.H1{id: id, content: String.replace(content, "# ", "")}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.H2) do
    %Block.H2{id: id, content: content}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.H3) do
    %Block.H2{id: id, content: content}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.Pre) do
    %Block.Pre{id: id, content: String.replace(content, "```", "")}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.Blockquote) do
    %Block.Blockquote{id: id, content: String.replace(content, "> ", "")}
  end

  defp transform(%__MODULE__{id: id, content: content}, Block.Li) do
    %Block.Li{id: id, content: String.replace(content, "* ", "")}
  end
end
