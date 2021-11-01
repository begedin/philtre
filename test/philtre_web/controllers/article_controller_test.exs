defmodule PhiltreWeb.ArticleControllerTest do
  @moduledoc false
  use PhiltreWeb.ConnCase

  alias Philtre.Articles
  alias Philtre.Factories

  describe "GET /" do
    test "renders list of articles", %{conn: conn} do
      [article_1, article_2] = Factories.create_articles(2)

      dom = conn |> get("/") |> html_response(200) |> Floki.parse_document!()

      assert Floki.text(dom) =~ article_1.title
      assert Floki.text(dom) =~ article_2.title
    end
  end

  defp article_path(%Articles.Article{slug: slug}), do: "/#{slug}"

  describe "GET /:slug" do
    test "renders article", %{conn: conn} do
      article = Factories.create_article()

      path = article_path(article)
      dom = conn |> get(path) |> html_response(200) |> Floki.parse_document!()

      assert Floki.text(dom) =~ article.title
      assert Floki.text(dom) =~ article.body
    end

    test "renders 404 if article not found", %{conn: conn} do
      assert conn |> get("/foo") |> html_response(404) =~ "Not Found"
    end
  end
end
