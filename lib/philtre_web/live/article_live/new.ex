defmodule PhiltreWeb.ArticleLive.New do
  @moduledoc """
  Implements the page for creation of a new article.
  """
  use PhiltreWeb, :live_view

  alias PhiltreWeb.ArticleLive.ArticleForm

  def mount(%{}, _session, socket) do
    {:ok, socket}
  end
end
