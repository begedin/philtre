defmodule PhiltreWeb.ArticleLive.Edit do
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, article} = Articles.get_article(slug)
    changeset = Articles.changeset(article)

    socket = assign(socket, %{article: article, changeset: changeset})

    {:ok, socket}
  end

  def handle_event("save", %{"article" => params}, socket) do
    case Articles.update_article(socket.assigns.article, params) do
      {:ok, _} ->
        socket = push_redirect(socket, to: "/articles")
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :changeset, changeset)
        {:noreply, socket}
    end
  end
end
