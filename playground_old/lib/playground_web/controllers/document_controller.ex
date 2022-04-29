defmodule PlaygroundWeb.DocumentController do
  use PlaygroundWeb, :controller

  alias Playground.Documents
  alias Plug.Conn

  @spec index(Conn.t(), map) :: Conn.t()
  def index(conn, %{}) do
    documents = Documents.list_documents()
    render(conn, "index.html", documents: documents)
  end

  @spec show(Conn.t(), map) :: Conn.t()
  def show(conn, %{"filename" => filename}) do
    case Documents.get_document(filename) do
      {:ok, document} ->
        render(conn, "show.html", document: document)

      {:error, :not_found} ->
        conn
        |> put_view(PlaygroundWeb.ErrorView)
        |> put_status(:not_found)
        |> render("404.html")
    end
  end
end
