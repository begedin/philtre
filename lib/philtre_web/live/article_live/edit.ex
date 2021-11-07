defmodule PhiltreWeb.ArticleLive.Edit do
  @moduledoc """
  Implements the page for editing of an existing article.
  """
  use PhiltreWeb, :live_view

  alias PhiltreWeb.ArticleLive.ArticleForm

  @spec mount(map, %LiveView.Session{}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, assign(socket, %{slug: slug})}
  end
end
