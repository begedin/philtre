defmodule Editor.SerializerTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Philtre.Block.Code
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Cell
  alias Philtre.Block.Table
  alias Philtre.Editor

  test "works" do
    assert Editor.Serializer.serialize(%Editor{}) == %{"blocks" => [], "id" => nil}
  end

  describe "normalize/serialize" do
    test "is idempotent for code" do
      code = %Code{id: "foo", content: "# a comment \n # another comment \n\n", language: "elixir"}
      assert code |> Editor.serialize() |> Editor.normalize() == code
    end

    test "is idempotent for table" do
      table = %Table{
        id: "foo",
        header_rows: [
          ["header 1", "header 2"]
        ],
        rows: [
          ["foo", "bar"],
          ["baz", "bam"]
        ]
      }

      assert table |> Editor.serialize() |> Editor.normalize() == table
    end

    test "is idempotent for contenteditable" do
      editable = %ContentEditable{
        id: "foo",
        kind: "pre",
        cells: [
          %Cell{id: "cell_foo", modifiers: ["strong"], text: "A cell"},
          %Cell{id: "cell_bar", modifiers: [], text: "Another cell"}
        ]
      }

      assert editable |> Editor.serialize() |> Editor.normalize() == editable
    end
  end
end
