defmodule Editor.SerializerTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Philtre.Editor

  test "works" do
    assert Editor.Serializer.serialize(%Editor{}) == %{"blocks" => [], "id" => nil}
  end
end
