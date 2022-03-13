defmodule Editor.Block.P do
  @moduledoc """
  Holds logic specific to the p block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.Utils

  # struct

  defstruct active: false, pre_caret: "", post_caret: "", id: Utils.new_id()

  @type t :: %__MODULE__{}

  # component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <p
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></p>
    """
  end

  defp content(%{block: %{active: true}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> Utils.caret() <> @block.post_caret)  %>
    """
  end

  defp content(%{block: %{active: false}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> @block.post_caret)  %>
    """
  end

  def handle_event("update", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    pre_caret = cleanup(pre_caret)
    post_caret = cleanup(post_caret)

    old_block = socket.assigns.block
    new_block = %{old_block | pre_caret: pre_caret, post_caret: post_caret, active: true}

    new_block =
      case transform_type(pre_caret) do
        nil -> new_block
        other -> transform(new_block, other)
      end

    Editor.send_event(
      socket,
      "replace",
      %{block: socket.assigns.block, with: [new_block]}
    )

    {:noreply, socket}
  end

  def handle_event("split_line", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    pre_caret = cleanup(pre_caret) <> "<br/>"
    post_caret = cleanup(post_caret)

    new_block = %{block | active: true, pre_caret: pre_caret, post_caret: post_caret}

    Editor.send_event(socket, "replace", %{block: block, with: new_block})
    {:noreply, socket}
  end

  def handle_event("split_block", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | active: false, pre_caret: pre_caret, post_caret: ""}

    new_block = %__MODULE__{
      id: Utils.new_id(),
      active: true,
      pre_caret: "",
      post_caret: post_caret
    }

    Editor.send_event(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("paste_blocks", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | active: false, pre_caret: pre_caret, post_caret: ""}

    new_block = %__MODULE__{
      id: Utils.new_id(),
      active: true,
      pre_caret: "",
      post_caret: post_caret
    }

    Editor.send_event(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    Editor.send_event(socket, "merge_previous", %{block: socket.assigns.block})
    {:noreply, socket}
  end

  # api

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

  def merge(%__MODULE__{} = self, %__MODULE__{} = other) do
    %{
      self
      | active: true,
        pre_caret: self.pre_caret <> self.post_caret,
        post_caret: other.pre_caret <> other.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.H1) do
    %Block.H1{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "# ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.H2) do
    %Block.H2{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "## ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.H3) do
    %Block.H3{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "### ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.Pre) do
    %Block.Pre{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "```", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.Blockquote) do
    %Block.Blockquote{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "> ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%__MODULE__{} = self, Block.Li) do
    %Block.Li{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "* ", ""),
      post_caret: self.post_caret
    }
  end
end
