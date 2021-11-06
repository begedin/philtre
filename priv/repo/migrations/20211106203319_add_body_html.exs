defmodule Philtre.Repo.Migrations.AddBodyHtml do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add(:body_html, :text, null: false, default: "")
    end
  end
end
