defmodule Philtre.Block.Code do
  @moduledoc """
  Elixir-side implementation of the code-type block

  This block is used to write code in a synthax-highlighted UI. The frontend
  aspect of it is implemented in `hooks/Code.ts`
  """
  use Phoenix.Component

  alias Philtre.Block
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Selection
  alias Philtre.Editor
  alias Philtre.Editor.Utils

  require Logger

  @behaviour Block

  defstruct id: nil, content: "", language: "elixir", focused: false

  @type t :: %__MODULE__{}

  @impl Block
  def id(%__MODULE__{id: id}), do: id

  @impl Block
  def type(%__MODULE__{}), do: "code"

  @impl Block
  def data(%__MODULE__{language: language, content: content}) do
    %{"language" => language, "content" => content}
  end

  @impl Block
  def normalize(id, %{"language" => language, "content" => content}) do
    %__MODULE__{
      id: id,
      language: language,
      content: content
    }
  end

  @impl Block
  def render_live(%{block: _} = assigns) do
    # data-language is used to get the language in the frontend hook, which is
    # then used by the frontend-based code-highlighting library
    ~H"""
    <div
      class="philtre__code"
      data-block
      data-language={@block.language}
      id={@block.id}
      phx-hook="Code"
      phx-update="ignore"
      phx-target={@myself}
    >
      <.language language={@block.language} myself={@myself} />
      <pre><code class="philtre__code__highlighted"><%= @block.content %></code></pre>
      <textarea
        class="philtre__code__editable"
        spellcheck="false"
        autofocus={@block.focused}
        rows={rows(@block.content)}
      ><%= @block.content %></textarea>
    </div>
    """
  end

  defp language(%{} = assigns) do
    ~H"""
    <div class="philtre__code__language">
      <form phx-change="set_language" phx-target={@myself}>
        <select name="language" value={@language}>
          <option value="elixir">Elixir</option>
          <option value="javascript">Javascript</option>
        </select>
      </form>
    </div>
    """
  end

  defp rows(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.count()
  end

  @impl Block
  def render_static(%{block: _} = assigns) do
    ~H"<pre><%= @block.content %></pre>
"
  end

  def handle_event("update", %{"value" => value}, socket) do
    new_block = %{socket.assigns.block | content: value}
    new_editor = Editor.replace_block(socket.assigns.editor, socket.assigns.block, [new_block])

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("add_block", %{} = params, socket) do
    Logger.debug("add_block: #{inspect(params)}")

    %__MODULE__{} = block = socket.assigns.block

    cell = ContentEditable.Cell.new()

    new_block = %ContentEditable{
      id: Utils.new_id(),
      kind: "p",
      cells: [cell],
      selection: ContentEditable.Selection.new_start_of(cell)
    }

    new_editor = Editor.replace_block(socket.assigns.editor, block, [block, new_block])

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("set_language", %{"language" => language} = params, socket) do
    Logger.debug("set_block: #{inspect(params)}")

    new_block = %{socket.assigns.block | language: language}
    new_editor = Editor.replace_block(socket.assigns.editor, socket.assigns.block, [new_block])

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  @impl Block
  @spec transform(ContentEditable.t()) :: t
  def transform(%ContentEditable{} = _block) do
    %__MODULE__{id: Utils.new_id(), content: "", language: "elixir", focused: true}
  end

  @impl Block
  def reduce(%__MODULE__{} = block), do: block

  @impl Block
  def set_selection(%__MODULE__{} = block, %Selection{}) do
    # We do not set selection on code block from BE yet
    block
  end

  @impl Block
  def cells(%__MODULE__{}), do: []
end
