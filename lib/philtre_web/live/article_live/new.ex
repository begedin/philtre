defmodule PhiltreWeb.ArticleLive.New do
  use PhiltreWeb, :live_view

  alias PhiltreWeb.ArticleLive.ArticleForm

  def mount(%{}, _session, socket) do
    {:ok, socket}
  end
end
