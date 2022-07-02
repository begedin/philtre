defmodule Philtre.Block.TableTest do
  @moduledoc false
  import Phoenix.LiveViewTest
  use ExUnit.Case

  alias Philtre.Block.Table

  describe "render_static" do
    test "renders" do
      rendered =
        render_component(&Table.render_static/1,
          block: %Table{
            header_rows: [["foo", "bar"]],
            rows: [["a", "b"], ["c", "d"]]
          }
        )

      assert Floki.parse_document!(rendered) == [
               {
                 "table",
                 [],
                 [
                   {
                     "thead",
                     [],
                     [
                       {
                         "tr",
                         [],
                         [{"th", [], ["foo"]}, {"th", [], ["bar"]}]
                       }
                     ]
                   },
                   {
                     "tbody",
                     [],
                     [
                       {
                         "tr",
                         [],
                         [{"td", [], ["a"]}, {"td", [], ["b"]}]
                       },
                       {"tr", [], [{"td", [], ["c"]}, {"td", [], ["d"]}]}
                     ]
                   }
                 ]
               }
             ]
    end
  end
end
