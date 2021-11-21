defmodule PhiltreWeb.ArticleLive.Edit do
  @moduledoc """
  Implements the page for editing of an existing article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, %Articles.Article{} = article} = Articles.get_article(slug)
    {:ok, assign(socket, %{article: article, page: Editor.normalize(article.content)})}
  end

  def handle_event("save", %{}, socket) do
    %Articles.Article{} = article = socket.assigns.article
    %Editor.Page{} = page = socket.assigns.page

    case Articles.update_article(article, page) do
      {:ok, _article} ->
        {:noreply, push_redirect(socket, to: "/articles")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "There were some errors saving the article")}
    end
  end

  def handle_info({:updated_page, page}, socket) do
    {:noreply, assign(socket, :page, page)}
  end
end
