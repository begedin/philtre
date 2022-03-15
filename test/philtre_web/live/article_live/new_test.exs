defmodule PhiltreWeb.ArticleLive.NewTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Editor.Block
  alias Philtre.Articles
  alias Philtre.Factories

  @editor %Editor{
    id: "-1",
    blocks: [
      %Block{id: "1", pre_caret: "Foo", type: "h1"},
      %Block{id: "2", pre_caret: "Bar", type: "p"},
      %Block{id: "3", pre_caret: "Baz", type: "p"}
    ]
  }

  test "creates article", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    send(view.pid, {:update, @editor})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert {:ok, %{content: content}} = Articles.get_article("foo")

    assert content == %{
             "blocks" => [
               %{"id" => "1", "type" => "h1", "content" => "Foo"},
               %{"id" => "2", "type" => "p", "content" => "Bar"},
               %{"id" => "3", "type" => "p", "content" => "Baz"}
             ],
             "id" => "-1"
           }
  end

  test "can select,then copy and paste blocks", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    send(view.pid, {:update, @editor})

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    view
    |> element("[id=editor__selection__#{@editor.id}]")
    |> render_hook("select_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert editor.selected_blocks == block_ids

    view
    |> element("[id=editor__selection__#{@editor.id}]")
    |> render_hook("copy_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)

    assert [
             %Editor.Block{active: false, post_caret: "", pre_caret: "Foo", type: "h1"},
             %Editor.Block{active: false, post_caret: "", pre_caret: "Bar", type: "p"}
           ] = editor.clipboard

    block = Enum.at(@editor.blocks, 0)

    view
    |> element("[id^=#{block.id}]")
    |> render_hook("paste_blocks", %{"pre" => "Fo", "post" => "o"})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert Enum.count(editor.blocks) == 6
    assert Editor.text(editor) == "FoFooBaroBarBaz"
  end

  test "validates validation errors", %{conn: conn} do
    article = Factories.create_article()
    {:ok, view, _html} = live(conn, "/articles/new")

    editor = %Editor{
      id: "100",
      blocks: [
        %Block{id: "1", pre_caret: Articles.Article.title(article), type: "h1"}
      ]
    }

    send(view.pid, {:update, editor})

    assert html = view |> element("button") |> render_click()
    assert html =~ "There were some errors"
  end
end
