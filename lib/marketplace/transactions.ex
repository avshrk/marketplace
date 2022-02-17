defmodule Marketplace.Transactions do
  @moduledoc """
  Context for Transaction
  """
  alias Marketplace.Repo
  alias Marketplace.Transaction
  alias Marketplace.Visit
  alias Marketplace.Visits

  import Ecto.Query

  @net_amount 0.85

  @type insurance_credit_input :: %{
          required(:member_id) => integer(),
          required(:amount) => number()
        }

  @type transaction_return :: {:ok, Transaction.t()} | {:error, String.t()}

  @spec insurance_credit(insurance_credit_input) :: transaction_return
  def insurance_credit(%{member_id: member_id, amount: amount}) do
    %{member_id: member_id, amount: amount}
    |> process_credit()
  end

  @spec debit(Visit.t()) :: transaction_return
  def debit(%Visit{member_id: member_id, minutes: minutes, id: visit_id} = params) do
    balance = current_balance(member_id) - minutes

    params
    |> Map.from_struct()
    |> Map.merge(%{
      debit: minutes,
      balance: balance,
      visit_id: visit_id
    })
    |> insert()
  end

  @spec credit(Visit.t()) :: transaction_return
  def credit(%Visit{minutes: minutes, pal_id: pal_id, id: visit_id} = params) do
    params
    |> Map.from_struct()
    |> Map.merge(%{
      amount: minutes |> net_amount(),
      member_id: pal_id,
      visit_id: visit_id
    })
    |> process_credit()
  end

  @spec current_available_balance(integer) :: integer()
  def current_available_balance(member_id) do
    pending_minutes =
      member_id
      |> Visits.member_pending_request_total_minutes()

    current_balance = member_id |> current_balance()
    current_balance - pending_minutes
  end

  @spec current_balance(integer) :: integer()
  def current_balance(member_id) do
    member_id
    |> member_current_balance_query()
    |> Repo.all()
    |> handle_decimal()
  end

  defp process_credit(%{member_id: member_id, amount: amount} = params) do
    member_current_balance = member_id |> current_balance()

    params
    |> Map.merge(%{
      credit: amount,
      balance: member_current_balance + amount
    })
    |> insert()
  end

  defp member_current_balance_query(member_id) do
    from(t in Transaction,
      where: t.member_id == ^member_id,
      order_by: [desc: :updated_at, desc: :id],
      limit: 1,
      select: t.balance
    )
  end

  defp insert(params) do
    %Transaction{}
    |> Transaction.changeset(params)
    |> Repo.insert()
  end

  defp net_amount(amount) do
    amount * @net_amount
  end

  defp handle_decimal([]), do: 0
  defp handle_decimal([nil]), do: 0
  defp handle_decimal([amount]), do: amount |> Decimal.to_float()
end
