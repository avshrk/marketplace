defmodule Marketplace.Repo.Migrations.CreateVisitsTable do
  use Ecto.Migration

  def change do
    create table(:visits) do
      add(:visit_date, :date, null: false)
      add(:minutes, :integer, null: false)
      add(:tasks, :text, null: false)
      add(:accepted_at, :naive_datetime)
      add(:declined_at, :naive_datetime)
      add(:member_id, references(:users), null: false)
      add(:pal_id, references(:users), null: false)

      timestamps()
    end

    create(index(:visits, [:member_id]))
    create(index(:visits, [:pal_id]))
  end
end
