defmodule Philtre.TableTest do
  @moduledoc false
  import Phoenix.LiveViewTest
  use ExUnit.Case

  alias Philtre.Table

  describe "read_only" do
    test "renders" do
      rendered =
        render_component(&Table.read_only/1,
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
