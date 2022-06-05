defmodule Philtre.PageTest do
  @moduledoc false

  use Philtre.EditorCase

  import Phoenix.LiveViewTest

  alias Philtre.Editor
  alias Philtre.UI.Page

  defmodule TestView do
    @moduledoc false

    use Phoenix.LiveView

    import Phoenix.LiveView.Helpers
    import Phoenix.LiveViewTest

    alias Philtre.Editor

    @doc false
    @impl Phoenix.LiveView
    def mount(:not_mounted_at_router, _session, socket) do
      {:ok, assign(socket, :editor, Editor.new())}
    end

    @doc false
    @impl Phoenix.LiveView
    def render(assigns) do
      ~H"""
      <.live_component module={Page} id={@editor.id} editor={@editor} />
      """
    end
  end

  defp get_editor(view_pid) when is_pid(view_pid) do
    view_pid
    |> :sys.get_state()
    |> Map.get(:components)
    |> Kernel.elem(0)
    |> Enum.find(fn {_key, {module, _id, _assigns, _, _}} -> module == Page end)
    |> Kernel.elem(1)
    |> Kernel.elem(2)
    |> Map.get(:editor)
  end

  def get_rendered_blocks(html) when is_binary(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-block]")
  end

  test "cann add and remove blocks using buttons", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TestView)

    assert html
           |> Floki.parse_document!()
           |> Floki.find("[data-block]")
           |> Enum.count() == 2

    %Editor{blocks: [_h1, p]} = get_editor(view.pid)

    assert [{"h1", _, _}, {"p", _, _}, {"p", _, _}] =
             view
             |> element(~s|button[phx-click="add_block"][phx-value-block_id=#{p.id}"|)
             |> render_click()
             |> get_rendered_blocks()

    %Editor{blocks: [_h1, _p, p_new]} = get_editor(view.pid)

    assert [{"h1", _, _}, {"p", _, _}] =
             view
             |> element(~s|button[phx-click="remove_block"][phx-value-block_id=#{p_new.id}"|)
             |> render_click()
             |> get_rendered_blocks()
  end

  test "can shift focus between blocks", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TestView)

    assert [{"div", attrs, _}] =
             html
             |> Floki.parse_document!()
             |> Floki.find("[data-focused]")

    assert {"id", "section_1"} in attrs
    assert {"tabindex", "1"} in attrs

    assert [{"div", attrs, _}] =
             view
             |> element("#section_1")
             |> render_hook("focus_previous")
             |> Floki.parse_document!()
             |> Floki.find("[data-focused]")

    assert {"id", "section_0"} in attrs
    assert {"tabindex", "0"} in attrs

    assert [{"div", attrs, _}] =
             view
             |> element("#section_0")
             |> render_hook("focus_next")
             |> Floki.parse_document!()
             |> Floki.find("[data-focused]")

    assert {"id", "section_1"} in attrs
    assert {"tabindex", "1"} in attrs

    %Editor{blocks: [h1, _p]} = get_editor(view.pid)

    assert [{"div", attrs, _}] =
             view
             |> element("#section_0")
             |> render_hook("focus_current", %{"block_id" => h1.id})
             |> Floki.parse_document!()
             |> Floki.find("[data-focused]")

    assert {"id", "section_0"} in attrs
    assert {"tabindex", "0"} in attrs
  end
end
