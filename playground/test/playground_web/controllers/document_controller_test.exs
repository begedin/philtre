defmodule PlaygroundWeb.DocumentControllerTest do
  @moduledoc false
  use PlaygroundWeb.ConnCase

  alias Playground.Documents

  describe "GET /" do
    test "renders list of articles", %{conn: conn} do
      Documents.save_document(%Editor{}, "foo")
      Documents.save_document(%Editor{}, "bar")

      dom = conn |> get("/") |> html_response(200) |> Floki.parse_document!()

      assert Floki.text(dom) =~ "foo.json"
      assert Floki.text(dom) =~ "bar.json"
    end
  end

  describe "GET /:slug" do
    test "renders article", %{conn: conn} do
      editor = %Editor{}

      Documents.save_document(editor, "foo")

      dom = conn |> get("/foo.json") |> html_response(200) |> Floki.parse_document!()

      assert Floki.text(dom) =~ Editor.text(editor)

      Documents.delete_document("foo")
    end

    test "renders 404 if article not found", %{conn: conn} do
      assert conn |> get("/uknown") |> html_response(404) =~ "Not Found"
    end
  end
end
