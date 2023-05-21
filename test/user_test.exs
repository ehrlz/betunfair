defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  setup_all do
    UserDatabase.start_users([])
    :ok
    on_exit(fn -> UserDatabase.clear() end)
  end

  test "create_user" do
    UserDatabase.clear()
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.add_user(1, "dani") == {:error, :user_already_exists}
  end

  test "deposit and withdraw" do
    UserDatabase.clear()
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.user_deposit(1, 10) == :ok
    assert UserDatabase.user_deposit(2, 10) == {:error, :user_does_not_exist}
    assert UserDatabase.user_withdraw(1, 5) == :ok
    assert UserDatabase.user_withdraw(1, 10) == {:error, :not_enough_money_to_withdraw}
    assert UserDatabase.user_withdraw(2, 10) == {:error, :user_does_not_exist}
  end

  test "get user" do
    UserDatabase.clear()
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.user_get(1) == {:ok, %User{name: "dani", id: 1, balance: 0}}
    assert UserDatabase.user_get(2) == {:error, :user_not_found}
  end
end
