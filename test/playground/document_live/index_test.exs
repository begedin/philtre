defmodule Playground.DocumentLive.IndexTest do
  @moduledoc false

  use Playground.ConnCase

  import Phoenix.LiveViewTest

  alias Playground.Documents

  test "renders articles", %{conn: conn} do
    Documents.save_document(%Editor{}, "foo")
    Documents.save_document(%Editor{}, "bar")

    {:ok, _view, html} = live(conn, "/documents")

    dom = Floki.parse_document!(html)

    assert Floki.text(dom) =~ "foo.json"
    assert Floki.text(dom) =~ "bar.json"

    Documents.delete_document("foo")
    Documents.delete_document("bar")
  end
end
