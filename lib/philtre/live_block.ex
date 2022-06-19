defmodule Philtre.LiveBlock do
  @moduledoc """
  Single live component in charge of rendering all types of live blocks.

  Current implementation infers block type from struct module and simply
  delegates major callbacks to the bloc module.

  Later implementations might instead take block type from some sort of registry
  and require some sort of return format from the block modules, to decide how
  to render them.

  Ideally, we want individual blocks to be decoupled from the editor.
  """
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %module{}} = assigns) do
    module.render(assigns)
  end

  def handle_event(event, payload, socket) do
    %module{} = socket.assigns.block
    module.handle_event(event, payload, socket)
  end
end
