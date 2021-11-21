defmodule Philtre.Repo.Migrations.SimplifySchema do
  @moduledoc """
  Simplifies article schema further by just storing the json representation of
  an editor page as a field
  """
  use Ecto.Migration

  def change do
    alter table(:articles) do
      Philtre.Repo.delete_all("articles")

      remove(:sections, {:array, :map}, null: false)
      add(:content, :map, null: false)
    end
  end
end
