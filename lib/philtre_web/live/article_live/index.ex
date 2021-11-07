defmodule PhiltreWeb.ArticleLive.Index do
  @moduledoc """
  Implements the page for listing articles in the admin interface.

  From here, users can manage each individual article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    socket = assign(socket, :articles, Articles.list_articles())

    {:ok, socket}
  end
end
