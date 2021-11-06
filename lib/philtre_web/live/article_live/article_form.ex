defmodule PhiltreWeb.ArticleLive.ArticleForm do
  use PhiltreWeb, :live_component

  alias Philtre.Articles

  @spec update(
          %{optional(:slug) => String.t()},
          LiveView.Socket.t()
        ) :: {:ok, LiveView.Socket.t()}
  def update(%{slug: slug}, socket) do
    {:ok, %Articles.Article{} = article} = Articles.get_article(slug)
    {:ok, assign(socket, assigns(article))}
  end

  def update(%{}, socket) do
    {:ok, assign(socket, assigns())}
  end

  @spec assigns(Articles.Article.t()) :: map
  defp assigns(%Articles.Article{} = article) do
    %{
      article: article,
      changeset: Articles.changeset(article),
      preview: preview(article.body)
    }
  end

  @spec assigns :: map
  defp assigns() do
    %{
      changeset: Articles.changeset(),
      preview: preview("")
    }
  end

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}
  def handle_event("preview", %{"value" => value}, socket) do
    socket = assign(socket, :preview, Earmark.as_html!(value))
    {:noreply, socket}
  end

  def handle_event("save", %{"article" => params}, socket) do
    result =
      if socket.assigns[:article] do
        Articles.update_article(socket.assigns.article, params)
      else
        Articles.create_article(params)
      end

    case result do
      {:ok, _} ->
        socket = push_redirect(socket, to: "/articles")
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :changeset, changeset)
        {:noreply, socket}
    end
  end

  @spec preview(String.t()) :: String.t()
  defp preview(value) when is_binary(value) do
    Earmark.as_html!(value)
  end
end
