defmodule Philtre.Block.CodeTest do
  @moduledoc false
  import Phoenix.LiveViewTest
  use ExUnit.Case

  alias Philtre.Block.Code

  describe "read_only" do
    test "renders" do
      rendered =
        render_component(&Code.read_only/1,
          block: %Code{
            content:
              Enum.join(
                [
                  "defmodule Foo do",
                  "  def foo do",
                  "    Logger.info(:bar)",
                  "  end",
                  "end"
                ],
                "/n"
              ),
            language: "elixir"
          }
        )

      assert Floki.parse_document!(rendered) == [
               {
                 "pre",
                 [],
                 [
                   "defmodule Foo do/n  def foo do/n    Logger.info(:bar)/n  end/nend"
                 ]
               }
             ]
    end
  end
end
