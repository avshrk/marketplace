defmodule Marketplace do
  @moduledoc """
  Marketpalce Api
  """

  alias Marketplace.{
    Transaction,
    Transactions,
    User,
    Visit,
    Visits
  }

  @type request_input :: Visits.request_input()
  @type visit :: {:ok, Visit.t()} | {:error, String.t()}
  @type visits :: [Visit.t()] | []
  @type transaction :: {:ok, Transaction.t()} | {:error, String.t()}
  @type insurance_credit :: Transactions.insurance_credit_input()
  @type user_input :: User.crate_input()
  @type user :: {:ok, User.t()} | {:error, String.t()}

  @spec create_user(user_input) :: user
  defdelegate create_user(user_args), to: User, as: :create

  @spec request_visit(request_input) :: visit
  defdelegate request_visit(request_args), to: Visits, as: :make_request

  @spec decline_request(integer()) :: visit
  defdelegate decline_request(visit_id), to: Visits

  @spec accept_request(integer()) :: visit
  defdelegate accept_request(visit_id), to: Visits

  @spec all_requests_by_member(integer()) :: visits
  defdelegate all_requests_by_member(member_id), to: Visits

  @spec all_requests_for_pal(integer()) :: visits
  defdelegate all_requests_for_pal(pal_id), to: Visits

  @spec pending_requests_by_member(integer()) :: visits
  defdelegate pending_requests_by_member(member_id), to: Visits

  @spec pending_requests_for_pal(integer()) :: visits
  defdelegate pending_requests_for_pal(pal_id), to: Visits

  @spec current_available_balance(integer()) :: integer()
  defdelegate current_available_balance(member_id), to: Transactions

  @spec current_balance(integer()) :: integer()
  defdelegate current_balance(member_id), to: Transactions

  @spec insurance_credit(insurance_credit) :: transaction
  defdelegate insurance_credit(insurance_args), to: Transactions
end
