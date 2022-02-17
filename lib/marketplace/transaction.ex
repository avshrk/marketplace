defmodule Marketplace.Transaction do
  @moduledoc """
  Schema for Transactions Table
  """
  import Ecto.Changeset

  use Ecto.Schema

  alias Marketplace.{
    User,
    Visit
  }

  @type t :: %__MODULE__{}

  schema "transactions" do
    field(:debit, :decimal)
    field(:credit, :decimal)
    field(:balance, :decimal)

    belongs_to(:member, User, foreign_key: :member_id)
    belongs_to(:visit, Visit)
    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :member_id,
      :debit,
      :credit,
      :balance,
      :visit_id
    ])
    |> validate_required([:balance, :member_id])
    |> validate_required_one_of_two([:debit, :credit])
  end

  defp validate_required_one_of_two(changeset, fields) do
    fields
    |> Enum.reject(fn field -> changeset |> get_field(field, false) end)
    |> Enum.count()
    |> validate(fields, changeset)
  end

  defp validate(1, _fields, changeset) do
    changeset
  end

  defp validate(0, fields, changeset) do
    changeset
    |> add_error(
      :required_one_of_two,
      "One of fields must be present: #{inspect(fields)}"
    )
  end

  defp validate(_, fields, changeset) do
    changeset
    |> add_error(
      :required_one_of_two,
      "Only one of the fields must be present: #{inspect(fields)}"
    )
  end
end
