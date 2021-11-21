defmodule PhiltreWeb.ArticleLive.IndexTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Factories

  test "renders articles", %{conn: conn} do
    [
      %{sections: [section_1 | _]},
      %{sections: [section_2 | _]}
    ] = Factories.create_articles(2)

    {:ok, _view, html} = live(conn, "/articles")

    dom = Floki.parse_document!(html)

    assert Floki.text(dom) =~ section_1.content
    assert Floki.text(dom) =~ section_2.content
  end
end
