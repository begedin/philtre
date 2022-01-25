defmodule PhiltreWeb.ArticleLive.NewTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Articles
  alias Philtre.Factories

  @editor %Editor{
    blocks: [
      %Editor.Block{
        id: "1",
        type: "h1",
        cells: [%Editor.Cell{id: "11", type: "span", content: "Foo"}]
      },
      %Editor.Block{
        id: "2",
        type: "p",
        cells: [%Editor.Cell{id: "22", type: "span", content: "Bar"}]
      },
      %Editor.Block{
        id: "3",
        type: "p",
        cells: [%Editor.Cell{id: "33", type: "span", content: "Baz"}]
      }
    ]
  }

  test "creates article", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    send(view.pid, {:update, @editor})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1 span[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p span[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert {:ok, %{content: content}} = Articles.get_article("foo")

    assert content == %{
             "blocks" => [
               %{
                 "cells" => [%{"content" => "Foo", "id" => "11", "type" => "span"}],
                 "id" => "1",
                 "type" => "h1"
               },
               %{
                 "cells" => [%{"content" => "Bar", "id" => "22", "type" => "span"}],
                 "id" => "2",
                 "type" => "p"
               },
               %{
                 "cells" => [%{"content" => "Baz", "id" => "33", "type" => "span"}],
                 "id" => "3",
                 "type" => "p"
               }
             ]
           }
  end

  test "can select,then copy and paste blocks", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    send(view.pid, {:update, @editor})

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    view
    |> element("[id^=editor__selection__]")
    |> render_hook("select_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert editor.selected_blocks == block_ids

    view
    |> element("[id^=editor__selection__]")
    |> render_hook("copy_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert editor.clipboard == Enum.take(@editor.blocks, 2)

    view
    |> element("[id^=editor__selection__]")
    |> render_hook("paste_blocks", %{
      "cell_id" => "11",
      "block_id" => "1",
      # pasting right after first "Foo"
      "index" => 3
    })

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert Enum.count(editor.blocks) == 6
    assert Editor.text(editor) == "FooFooBarBarBaz"
  end

  test "validates validation errors", %{conn: conn} do
    article = Factories.create_article()
    {:ok, view, _html} = live(conn, "/articles/new")

    editor = %Editor{
      blocks: [
        %Editor.Block{
          id: "1",
          type: "h1",
          cells: [%Editor.Cell{type: "span", content: Articles.Article.title(article)}]
        }
      ]
    }

    send(view.pid, {:update, editor})

    assert html = view |> element("button") |> render_click()
    assert html =~ "There were some errors"
  end
end
