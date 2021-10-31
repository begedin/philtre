defmodule PhiltreWeb.ArticleLive.Edit do
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  def mount(%{"id" => id}, _session, socket) do
    article = Articles.get_article(id)
    changeset = Articles.changeset(article)

    socket = assign(socket, %{article: article, changeset: changeset})

    {:ok, socket}
  end

  def handle_event("save", %{"article" => params}, socket) do
    {:ok, _} = Articles.update_article(socket.assigns.article, params)
    socket = push_redirect(socket, to: "/articles")
    {:noreply, socket}
  end
end
