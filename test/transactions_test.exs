defmodule Marketplace.TransactionsTest do
  use ExUnit.Case
  use Marketplace.RepoCase

  alias Marketplace.{
    Transactions,
    User,
    Visit
  }

  setup do
    {:ok, member} =
      %User{first_name: "first", last_name: "member", email: "first@member.com"}
      |> Repo.insert()

    {:ok, member2} =
      %User{first_name: "second", last_name: "member", email: "second@member.com"}
      |> Repo.insert()

    {:ok, pal} =
      %User{first_name: "first", last_name: "pal", email: "first@pal.com"}
      |> Repo.insert()

    {:ok, pal2} =
      %User{first_name: "second", last_name: "pal", email: "second@pal.com"}
      |> Repo.insert()

    today = Date.utc_today()

    {:ok, visit} =
      %Visit{
        accepted_at: ~N[2022-02-16 20:26:52],
        minutes: 30,
        visit_date: today,
        tasks: "Conversation",
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {
      :ok,
      member: member, member2: member2, pal: pal, pal2: pal2, visit: visit, today: today
    }
  end

  test "member gets credited by insurance", %{member: member} do
    {:ok, tran} =
      %{
        member_id: member.id,
        amount: 33
      }
      |> Transactions.insurance_credit()

    assert tran.credit |> Decimal.to_float() == 33.0
    assert tran.balance |> Decimal.to_float() == 33.0
    assert tran.member_id == member.id
    assert tran.visit_id == nil
  end

  test "pal gets net amount credited", %{pal: pal, visit: visit} do
    {:ok, tran} = visit |> Transactions.credit()

    assert tran.credit |> Decimal.to_float() == visit.minutes |> net_amount()
    assert tran.member_id == pal.id
    assert tran.visit_id == visit.id
  end

  test "member gets full visit amount debited", %{member: member, visit: visit} do
    {:ok, init_tran} =
      %{
        member_id: member.id,
        amount: 60
      }
      |> Transactions.insurance_credit()

    assert init_tran.balance |> Decimal.to_float() == 60

    {:ok, visit_tran} = visit |> Transactions.debit()

    assert visit_tran.balance |> Decimal.to_float() == 30
  end

  test "returns current balance of a member", %{
    member: member,
    visit: visit,
    today: today,
    pal: pal
  } do
    assert 0 == member.id |> Transactions.current_balance()

    %{
      member_id: member.id,
      amount: 100
    }
    |> Transactions.insurance_credit()

    assert 100 == member.id |> Transactions.current_balance()

    # debits 30 mins
    visit |> Transactions.debit()

    assert 70 == member.id |> Transactions.current_balance()

    {:ok, v2} =
      %Visit{
        minutes: 10,
        visit_date: today,
        tasks: "Conversation",
        member_id: pal.id,
        pal_id: member.id
      }
      |> Repo.insert()

    # credits 8.5
    v2 |> Transactions.credit()

    assert 78.5 == member.id |> Transactions.current_balance()
  end

  defp net_amount(amount) do
    (amount * 0.85)
    |> Float.round(2)
  end
end
