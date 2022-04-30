defmodule Playground.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Playground.ConnCase

      alias Playground.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint Playground.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
