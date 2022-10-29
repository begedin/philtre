defmodule Playground.Controller do
  use Phoenix.Controller, namespace: Playground

  import Plug.Conn

  plug(:put_view, Playground.View)
  plug(:put_layout, {Playground.View, :app})

  alias Playground.Documents
  alias Plug.Conn

  @spec index(Conn.t(), map) :: Conn.t()
  def index(conn, %{}) do
    documents = Documents.list_documents()
    render(conn, :index, documents: documents)
  end

  @spec show(Conn.t(), map) :: Conn.t()
  def show(conn, %{"filename" => filename}) do
    case Documents.get_document(filename) do
      {:ok, document} ->
        render(conn, :show, document: document)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:"404")
    end
  end
end
