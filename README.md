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
%{
  first_name: "Foo",
  last_name: "Bar",
  email: "foo@bar.com"
}
|> Marketplace.create_user()
```

* Depositing intial funds - insurance deposit
```elixir
%{member_id: 1, amount: 100}
|> Marketplace.insurance_credit()
```

* Requesting a visit.
* Visits are pending until accepted or declined.
* Requesting a visit will take pending minutes into account before allowing it to be created:
* current_balance > pending_minutes + requested_amount
```elixir
%{
  member_id: 1,
  pal_id: 2,
  minutes: 10,
  tasks: "Conversation",
  visit_date: ~D[2022-02-17]
}
|> Marketplace.request_visit()
```

* Accepting a request.
* Once a request is accepted or declined, it is completed.
* Once a visit completed, modification will not be allowed
* Accepting a request completes the request by setting `accepted_at` field, credits pal (minus overhead), and debits member.
* Overhead is not being tracked - only user balances are being tracked.
```elixir
visit_id
|> Marketplace.accept_request()
```

* Declining a request.
* (sets  `declined_at`)
```elixir
visit_id
|> Marketplace.decline_request()
```

* Getting all requests made by a member.
```elixir
member_id
|> Marketplace.all_request_by_member()
```

* Getting all visits requested from a pal.
```elixir
pal_id
|> Marketplace.all_requests_for_pal()
```
* Getting all pending requests made by a member.
```elixir
member_id
|> Marketplace.pending_requests_by_member()
```
* Getting all pending visits requested from a pal.
```elixir
pal_id
|> Marketplace.pending_requests_for_pal()
```
* This takes into account pending visits: current_balance - pending_requests
```elixir
member_id
|> Marketplace.current_available_balance()
```
* This is the balance persisted in transactions table.
```elixir
member_id
|> Marketplace.current_balance()
```


### Assumptions
* Authentication and Authorization are excluded
