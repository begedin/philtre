defmodule PhiltreWeb.ArticleLive.Edit do
  @moduledoc """
  Implements the page for editing of an existing article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, %Articles.Article{} = article} = Articles.get_article(slug)
    page = Editor.normalize(article.content)
    editor = %Editor{page: page}
    {:ok, assign(socket, %{article: article, editor: editor})}
  end

  @errors_saving "There were some errors saving the article"

  def handle_event("save", %{}, socket) do
    %Articles.Article{} = article = socket.assigns.article
    %Editor.Page{} = page = socket.assigns.editor.page

    case Articles.update_article(article, page) do
      {:ok, _article} -> {:noreply, push_redirect(socket, to: "/articles")}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, @errors_saving)}
    end
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
