defmodule Marketplace.Visits do
  @moduledoc """
  Context module for Visit
  """

  alias Ecto.Multi
  alias Marketplace.Repo
  alias Marketplace.Transaction
  alias Marketplace.Transactions
  alias Marketplace.Visit

  import Ecto.Query

  @type request_input :: %{
          required(:member_id) => integer(),
          required(:pal_id) => integer,
          required(:minutes) => integer(),
          required(:tasks) => String.t(),
          required(:visit_date) => Date.t()
        }

  @type accept_request_return :: %{
          :accept_request => Visit.t(),
          :debit_member => Transaction.t(),
          :credit_pal => Transaction.t()
        }

  @spec make_request(request_input) :: {:ok, Visit.t()} | {:error, String.t()}
  def make_request(
        %{
          member_id: member_id,
          pal_id: _pal_id,
          minutes: minutes,
          tasks: _tasks,
          visit_date: _visit_date
        } = params
      ) do
    member_id
    |> enough_minutes_available?(minutes)
    |> case do
      true -> params |> insert() |> IO.inspect()
      _ -> {:error, "Not enought minutes"}
    end
  end

  @spec decline_request(integer()) :: {:ok, Visit.t()} | {:error, String.t()}
  def decline_request(visit_id) do
    %{declined_at: DateTime.utc_now()}
    |> respond_to_request(visit_id)
  end

  @spec accept_request(integer()) :: {:ok, accept_request_return} | {:error, String.t()}
  def accept_request(visit_id) do
    Multi.new()
    |> Multi.run(
      :accept_request,
      &multi_respond_to_request(&1, &2, visit_id)
    )
    |> Multi.run(
      :debit_member,
      &multi_debit_member/2
    )
    |> Multi.run(
      :credit_pal,
      &multi_credit_pal/2
    )
    |> Repo.transaction()
  end

  @spec all_requests_by_member(integer) :: [Visit.t()] | []
  def all_requests_by_member(member_id) do
    member_id
    |> all_requests_by_member_query()
    |> Repo.all()
  end

  @spec all_requests_for_pal(integer) :: [Visit.t()] | []
  def all_requests_for_pal(pal_id) do
    pal_id
    |> all_requests_for_pal_query()
    |> Repo.all()
  end

  @spec pending_requests_by_member(integer) :: [Visit.t()] | []
  def pending_requests_by_member(member_id) do
    member_id
    |> pending_requests_by_member_query()
    |> Repo.all()
  end

  @spec pending_requests_for_pal(integer) :: [Visit.t()] | []
  def pending_requests_for_pal(pal_id) do
    pal_id
    |> pending_requests_for_pal_query()
    |> Repo.all()
  end

  @spec member_pending_request_total_minutes(integer()) :: number()
  def member_pending_request_total_minutes(member_id) do
    member_id
    |> member_pending_request_total_minutes_query()
    |> Repo.all()
    |> handle_decimal()
  end

  defp multi_respond_to_request(_repo, _res, visit_id) do
    %{accepted_at: DateTime.utc_now()}
    |> respond_to_request(visit_id)
  end

  defp multi_credit_pal(_repo, %{accept_request: visit}) do
    visit |> Transactions.credit()
  end

  defp multi_debit_member(_repo, %{accept_request: visit}) do
    visit |> Transactions.debit()
  end

  defp enough_minutes_available?(member_id, requested_minutes) do
    Transactions.current_available_balance(member_id) > requested_minutes
  end

  defp respond_to_request(resp, visit_id) do
    with visit = %Visit{} <- Visit |> Repo.get(visit_id),
         false <- visit |> is_complete?() do
      visit
      |> Visit.update_changeset(resp)
      |> Repo.update()
    else
      true -> {:error, "Completed visit can not be updated. Visit id: #{visit_id}"}
      _ -> {:error, "Visit not found. Visit id: #{visit_id}"}
    end
  end

  defp is_complete?(%Visit{accepted_at: nil, declined_at: nil}), do: false
  defp is_complete?(%Visit{accepted_at: _, declined_at: _}), do: true

  defp insert(params) do
    %Visit{}
    |> Visit.insert_changeset(params)
    |> Repo.insert()
  end

  defp member_pending_request_total_minutes_query(member_id) do
    base_query = member_id |> pending_requests_by_member_query()

    from(v in base_query,
      select: sum(v.minutes)
    )
  end

  defp pending_requests_by_member_query(member_id) do
    from(v in Visit,
      where: v.member_id == ^member_id,
      where: is_nil(v.accepted_at),
      where: is_nil(v.declined_at)
    )
  end

  defp pending_requests_for_pal_query(pal_id) do
    from(v in Visit,
      where: v.pal_id == ^pal_id,
      where: is_nil(v.accepted_at),
      where: is_nil(v.declined_at)
    )
  end

  defp all_requests_by_member_query(member_id) do
    from(v in Visit,
      where: v.member_id == ^member_id,
      order_by: [desc: :updated_at]
    )
  end

  defp all_requests_for_pal_query(pal_id) do
    from(v in Visit,
      where: v.pal_id == ^pal_id,
      order_by: [desc: :updated_at]
    )
  end

  defp handle_decimal([]), do: 0
  defp handle_decimal([nil]), do: 0
  defp handle_decimal([amount]), do: amount
end
