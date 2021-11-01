defmodule Philtre.Repo.Migrations.AddArticleSlug do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add(:slug, :string, null: false)
    end
  end
end
