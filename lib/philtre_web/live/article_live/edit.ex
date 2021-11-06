defmodule PhiltreWeb.ArticleLive.Edit do
  use PhiltreWeb, :live_view

  alias PhiltreWeb.ArticleLive.ArticleForm

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, assign(socket, %{slug: slug})}
  end
end
