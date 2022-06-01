defmodule Editor.SerializerTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Philtre.Code
  alias Philtre.Editor

  test "works" do
    assert Editor.Serializer.serialize(%Editor{}) == %{"blocks" => [], "id" => nil}
  end

  test "normalize/serialize is idempotent for code" do
    code = %Code{id: "foo", content: "# a comment \n # another comment \n\n", language: "elixir"}
    assert code |> Editor.serialize() |> Editor.normalize() == code
  end
end
