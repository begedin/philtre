defmodule Philtre.Repo.Migrations.AddArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add(:title, :string, null: false)
      add(:body, :text, null: false)
    end
  end
end
