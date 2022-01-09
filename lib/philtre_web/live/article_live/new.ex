defmodule PhiltreWeb.ArticleLive.New do
  @moduledoc """
  Implements the page for creation of a new article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, PhiltreWeb.session(), LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    {:ok, assign(socket, :editor, Editor.new())}
  end

  @errors_saving "There were some errors saving the article"

  def handle_event("save", %{}, socket) do
    %Editor.Page{} = page = socket.assigns.editor.page

    socket =
      case Articles.create_article(page) do
        {:ok, _article} -> push_redirect(socket, to: "/articles")
        {:error, _changeset} -> put_flash(socket, :error, @errors_saving)
      end

    {:noreply, socket}
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
