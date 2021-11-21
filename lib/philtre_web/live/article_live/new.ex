defmodule PhiltreWeb.ArticleLive.New do
  @moduledoc """
  Implements the page for creation of a new article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    {:ok, assign(socket, :page, Editor.Page.new())}
  end

  def handle_event("save", %{}, socket) do
    %Editor.Page{} = page = socket.assigns.page

    socket =
      case Articles.create_article(page) do
        {:ok, _article} ->
          push_redirect(socket, to: "/articles")

        {:error, _changeset} ->
          put_flash(socket, :error, "There were some errors saving the article")
      end

    {:noreply, socket}
  end

  def handle_info({:updated_page, page}, socket) do
    {:noreply, assign(socket, :page, page)}
  end
end
