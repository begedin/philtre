defmodule PhiltreWeb.ArticleLive.Index do
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  def mount(%{}, _session, socket) do
    socket = assign(socket, :articles, Articles.list_articles())

    {:ok, socket}
  end
end
