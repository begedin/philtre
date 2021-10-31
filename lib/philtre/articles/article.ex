defmodule Philtre.Articles.Article do
  use Ecto.Schema

  schema "articles" do
    field(:title, :string, null: false)
    field(:body, :string, null: false)
  end
end
