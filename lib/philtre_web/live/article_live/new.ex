defmodule PhiltreWeb.ArticleLive.New do
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  def mount(%{}, _session, socket) do
    socket = assign(socket, :changeset, Articles.changeset())

    {:ok, socket}
  end

  def handle_event("save", %{"article" => params}, socket) do
    {:ok, _} = Articles.create_article(params)
    socket = push_redirect(socket, to: "/articles")
    {:noreply, socket}
  end
end
