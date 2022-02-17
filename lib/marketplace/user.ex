defmodule Marketplace.User do
  @moduledoc """
  Schema for Users table
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Marketplace.Repo
  alias __MODULE__

  @type t :: %__MODULE__{}

  @type create_input :: %{
          required(:first_name) => String.t(),
          required(:last_name) => String.t(),
          required(:email) => String.t()
        }

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)

    has_many(:transactions, Marketplace.Transaction, foreign_key: :member_id)
    has_many(:visit_requests, Marketplace.Visit, foreign_key: :member_id)
    has_many(:visit_renders, Marketplace.Visit, foreign_key: :pal_id)

    timestamps()
  end

  @spec create(create_input) :: {:ok, User.t()} | {:error, String.t()}
  def create(params) do
    %User{}
    |> changeset(params)
    |> Repo.insert()
  end

  defp changeset(user, attrs) do
    user
    |> cast(attrs, [
      :first_name,
      :last_name,
      :email
    ])
    |> validate_required([:first_name, :last_name, :email])
  end
end
