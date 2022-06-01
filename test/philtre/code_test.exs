defmodule Philtre.CodeTest do
  @moduledoc false
  import Phoenix.LiveViewTest
  use ExUnit.Case

  alias Philtre.Code

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
                  "    IO.inspect(:bar)",
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
                   "defmodule Foo do/n  def foo do/n    IO.inspect(:bar)/n  end/nend"
                 ]
               }
             ]
    end
  end
end
