defmodule Marketplace.Repo.Migrations.CreateTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add(:member_id, references(:users), null: false)
      add(:debit, :decimal, precision: 7, scale: 2, default: 0)
      add(:credit, :decimal, precision: 7, scale: 2, default: 0)
      add(:balance, :decimal, precision: 7, scale: 2, default: 0)
      add(:visit_id, references(:visits))

      timestamps()
    end

    create(index(:transactions, [:member_id]))
    create(index(:transactions, [:visit_id]))
  end
end
