# Marketplace

### Requirements
* Elixir/Erlang/OTP
* Postgres

### Setup
* `mix deps.get`
* `mix ecto.setup`

### Tests
* `mix test`

### Runing
* `iex -S mix`

### Usage

* Creating a user - email needs to be unique
```elixir
Marketplace.create_user(%{first_name: "Foo", last_name: "Bar", email: "foo@bar.com"})
```

* Depositing intial funds - insurance deposit
```elixir
Marketplace.insurance_credit(%{member_id: 1, amount: 100})
```

* Requesting a visit.
* Visits are pending until accepted or declined.
* Requesting a visit will take pending minutes into account before allowing it to be created:
* current_balance > pending_minutes + requested_amount
```elixir
Marketplace.request_visit(%{ member_id: 1, pal_id: 2, minutes: 10, tasks: "Conversation", visit_date: ~D[2022-02-17] })
```

* Accepting a request.
* Once a request is accepted or declined, it is completed.
* Once a visit completed, modification will not be allowed
* Accepting a request completes the request by setting `accepted_at` field, credits pal (minus overhead), and debits member.
* Overhead is not being tracked - only user balances are being tracked.
```elixir
Marketplace.accept_request(visit_id)
```

* Declining a request.
* (sets  `declined_at`)
```elixir
Marketplace.decline_request(visit_id)
```

* Getting all requests made by a member.
```elixir
Marketplace.all_request_by_member(member_id)
```

* Getting all visits requested from a pal.
```elixir
Marketplace.all_requests_for_pal(pal_id)
```
* Getting all pending requests made by a member.
```elixir
Marketplace.pending_requests_by_member(member_id)
```
* Getting all pending visits requested from a pal.
```elixir
Marketplace.pending_requests_for_pal(pal_id)
```
* This takes into account pending visits: current_balance - pending_requests
```elixir
Marketplace.current_available_balance(member_id)
```
* This is the balance persisted in transactions table.
```elixir
Marketplace.current_balance(member_id)
```


### Assumptions
* Authentication and Authorization are excluded

