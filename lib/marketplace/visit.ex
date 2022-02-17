defmodule Marketplace.Visit do
  @moduledoc """
  Schema for Visits table
  """

  import Ecto.Changeset

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "visits" do
    field(:accepted_at, :naive_datetime)
    field(:declined_at, :naive_datetime)
    field(:minutes, :integer)
    field(:tasks, :string)
    field(:visit_date, :date)
    field(:member_id, :id)
    field(:pal_id, :id)

    has_many(:transactions, Marketplace.Transaction)

    timestamps()
  end

  def insert_changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :visit_date,
      :minutes,
      :tasks,
      :member_id,
      :pal_id
    ])
    |> validate_required([:visit_date, :minutes, :tasks, :member_id, :pal_id])
  end

  def update_changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :accepted_at,
      :declined_at
    ])
  end
end
