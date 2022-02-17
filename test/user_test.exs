defmodule Marketplace.UserTest do
  use ExUnit.Case
  use Marketplace.RepoCase

  alias Marketplace.User

  test "valid params create a user" do
    {:ok, new_user} =
             %{first_name: "Bar", last_name: "Foo", email: "foo@bar.email"}
             |> User.create()
    assert new_user.first_name == "Bar"
    assert new_user.last_name == "Foo"
    assert new_user.email == "foo@bar.email"
  end

  test "invalid params do not create a user" do
    {:error, changeset} =
             %{first_name: "Bar", last_name: "Foo"}
             |> User.create()


    assert changeset.errors  == [email: {"can't be blank", [validation: :required]}]
    assert changeset.valid? == false

  end
end

