defmodule Philtre.Repo.Migrations.SwitchToBlockBasedArticle do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      Philtre.Repo.delete_all("articles")

      remove(:title, :string, null: false)
      remove(:body, :text, null: false)
      remove(:body_html, :text, null: false, default: "")

      add(:sections, {:array, :map}, null: false)
    end
  end
end
