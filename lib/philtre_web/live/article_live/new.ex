defmodule PhiltreWeb.ArticleLive.New do
  @moduledoc """
  Implements the page for creation of a new article.
  """
  use PhiltreWeb, :live_view

  alias PhiltreWeb.ArticleLive.ArticleForm

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    {:ok, socket}
  end
end
