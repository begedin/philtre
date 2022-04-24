defmodule EditorTest.EditorCase do
  @moduledoc """
  Defines test case for testing of the editor component

  Effectively a ConnCase without db support and with an extra alias for a Wrapper module.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ConnTest

      alias EditorTest.Wrapper

      @endpoint PlaygroundWeb.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
