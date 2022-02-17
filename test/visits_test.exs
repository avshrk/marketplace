defmodule Marketplace.VisitsTest do
  use ExUnit.Case
  use Marketplace.RepoCase

  alias Marketplace.{
    Transaction,
    User,
    Visit,
    Visits
  }

  setup do
    {:ok, member} =
      %User{first_name: "first", last_name: "member", email: "first@member.com"}
      |> Repo.insert()

    {:ok, member2} =
      %User{first_name: "second", last_name: "member", email: "second@member.com"}
      |> Repo.insert()

    {:ok, _initial_deposit} =
      %Transaction{credit: 30, balance: 30, member_id: member.id}
      |> Repo.insert()

    {:ok, pal} =
      %User{first_name: "first", last_name: "pal", email: "first@pal.com"}
      |> Repo.insert()

    {:ok, pal2} =
      %User{first_name: "second", last_name: "pal", email: "second@pal.com"}
      |> Repo.insert()

    {
      :ok,
      member: member, member2: member2, pal: pal, pal2: pal2
    }
  end

  test "member makes a request", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:ok, request} =
      %{
        member_id: member.id,
        pal_id: pal.id,
        minutes: 10,
        tasks: "Conversation",
        visit_date: visit_date
      }
      |> Visits.make_request()

    assert request.minutes == 10.00
    assert request.tasks == "Conversation"
    assert request.visit_date == visit_date
    assert request.declined_at == nil
    assert request.accepted_at == nil
  end

  test "member can not make a request without enought minutes", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:error, "Not enought minutes"} =
      %{
        member_id: member.id,
        pal_id: pal.id,
        minutes: 60,
        tasks: "Long task",
        visit_date: visit_date
      }
      |> Visits.make_request()
  end

  test "member can not make request if pending request minutes larger than current balance", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    %Visit{
      minutes: 25,
      tasks: "pending tasks",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    {:error, "Not enought minutes"} =
      %{
        member_id: member.id,
        pal_id: pal.id,
        minutes: 60,
        tasks: "Long task",
        visit_date: visit_date
      }
      |> Visits.make_request()
  end

  test "pal can decline a request", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:ok, request} =
      %Visit{
        minutes: 25,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    assert request.accepted_at == nil
    assert request.declined_at == nil

    {:ok, declined_request} =
      request.id
      |> Visits.decline_request()

    refute declined_request.declined_at == request.declined_at
    assert declined_request.accepted_at == nil
  end

  test "pal can accept a request", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:ok, request} =
      %Visit{
        minutes: 25,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    assert request.accepted_at == nil
    assert request.declined_at == nil

    all_transactions_before = Transaction |> Repo.all()

    assert all_transactions_before |> length == 1

    [tran] = all_transactions_before
    assert tran.balance |> Decimal.to_float() == 30.0
    assert tran.credit |> Decimal.to_float() == 30.0
    assert tran.visit_id == nil
    assert tran.member_id == member.id

    {:ok,
     %{
       accept_request: visit,
       credit_pal: credit,
       debit_member: debit
     }} =
      request.id
      |> Visits.accept_request()

    assert visit.accepted_at != nil

    assert debit.visit_id == request.id
    assert debit.member_id == member.id
    assert debit.balance |> Decimal.to_float() == 5.0
    assert debit.debit |> Decimal.to_float() == 25.0

    assert credit.visit_id == request.id
    assert credit.member_id == pal.id
    assert credit.balance |> Decimal.to_float() == 21.25
    assert credit.credit |> Decimal.to_float() == request.minutes |> net()
  end

  test "pal can not modify completed visit", %{
    member: member,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:ok, request} =
      %Visit{
        accepted_at: ~N[2022-02-16 14:42:36],
        minutes: 25,
        tasks: "accepted tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    refute request.accepted_at == nil

    {:error, error_message} =
      request.id
      |> Visits.decline_request()

    assert error_message == "Completed visit can not be updated. Visit id: #{request.id}"
  end

  test "retrieves all requests made by a member", %{
    member: member,
    member2: member2,
    pal: pal
  } do
    visit_date = Date.utc_today()

    {:ok, _} =
      %Visit{
        minutes: 99,
        tasks: "other member tasks",
        visit_date: visit_date,
        member_id: member2.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v1} =
      %Visit{
        accepted_at: ~N[2022-02-16 14:42:36],
        minutes: 11,
        tasks: "accepted tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v2} =
      %Visit{
        minutes: 12,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v3} =
      %Visit{
        declined_at: ~N[2022-02-16 14:42:36],
        minutes: 13,
        tasks: "declined tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    all_requests =
      member.id
      |> Visits.all_requests_by_member()
      |> sort_requests_by_id_asc()

    assert all_requests |> length() == 3

    assert [v1.id, v2.id, v3.id] ==
             all_requests
             |> Enum.map(fn req -> req.id end)
  end

  test "retrieves all pending member's requests", %{
    member: member,
    member2: member2,
    pal: pal
  } do
    visit_date = Date.utc_today()

    %Visit{
      minutes: 99,
      tasks: "other member's pending task",
      visit_date: visit_date,
      member_id: member2.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    %Visit{
      accepted_at: ~N[2022-02-16 14:42:36],
      minutes: 11,
      tasks: "accepted tasks",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    {:ok, v2} =
      %Visit{
        minutes: 12,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    %Visit{
      declined_at: ~N[2022-02-16 14:42:36],
      minutes: 13,
      tasks: "declined tasks",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    [req] =
      member.id
      |> Visits.pending_requests_by_member()

    assert v2.id == req.id
    assert v2.tasks == req.tasks
  end

  test "retrieves all requests for pal", %{
    member: member,
    member2: member2,
    pal: pal,
    pal2: pal2
  } do
    visit_date = Date.utc_today()

    %Visit{
      minutes: 99,
      tasks: "pending tasks for other pal",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal2.id
    }
    |> Repo.insert()

    {:ok, v1} =
      %Visit{
        accepted_at: ~N[2022-02-16 14:42:36],
        minutes: 11,
        tasks: "accepted tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v2} =
      %Visit{
        declined_at: ~N[2022-02-16 14:42:36],
        minutes: 13,
        tasks: "declined tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v3} =
      %Visit{
        minutes: 8,
        tasks: "pending task from other member",
        visit_date: visit_date,
        member_id: member2.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v4} =
      %Visit{
        minutes: 9,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    requests =
      pal.id
      |> Visits.all_requests_for_pal()
      |> sort_requests_by_id_asc()

    assert requests |> length() == 4

    assert [v1.id, v2.id, v3.id, v4.id] ==
             requests
             |> Enum.map(fn req -> req.id end)
  end

  test "retrieves all pending requests for pal", %{
    member: member,
    member2: member2,
    pal: pal,
    pal2: pal2
  } do
    visit_date = Date.utc_today()

    %Visit{
      accepted_at: ~N[2022-02-16 14:42:36],
      minutes: 11,
      tasks: "accepted tasks",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    %Visit{
      declined_at: ~N[2022-02-16 14:42:36],
      minutes: 13,
      tasks: "declined tasks",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal.id
    }
    |> Repo.insert()

    %Visit{
      minutes: 99,
      tasks: "pending tasks for other pal",
      visit_date: visit_date,
      member_id: member.id,
      pal_id: pal2.id
    }
    |> Repo.insert()

    {:ok, v1} =
      %Visit{
        minutes: 8,
        tasks: "pending task from other member",
        visit_date: visit_date,
        member_id: member2.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    {:ok, v2} =
      %Visit{
        minutes: 9,
        tasks: "pending tasks",
        visit_date: visit_date,
        member_id: member.id,
        pal_id: pal.id
      }
      |> Repo.insert()

    requests =
      pal.id
      |> Visits.pending_requests_for_pal()
      |> sort_requests_by_id_asc()

    assert [v1.id, v2.id] ==
             requests
             |> Enum.map(fn req -> req.id end)
  end

  defp sort_requests_by_id_asc(requests) do
    requests
    |> Enum.sort(fn a, b -> a.id < b.id end)
  end

  defp net(amount) do
    amount * 0.85
  end
end
