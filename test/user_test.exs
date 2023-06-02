defmodule UserTest do
  use ExUnit.Case, async: false
  doctest UserDatabase

  setup do
    assert {:ok, _} = Betunfair.clean("userdb")
    assert {:ok, _} = Betunfair.start_link("userdb")
    assert true == Process.alive?(GenServer.whereis(MySupervisor))
    assert true == Process.alive?(GenServer.whereis(UserDatabase))

    :ok
  end

  test "create_user" do
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.add_user(1, "dani") == {:error, :user_already_exists}
  end

  test "deposit and withdraw" do
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.user_deposit(1, 10) == :ok
    assert UserDatabase.user_deposit(2, 10) == {:error, :user_not_found}
    assert UserDatabase.user_withdraw(1, 5) == :ok
    assert {:ok, %{balance: 5}} = UserDatabase.user_get(1)
    assert UserDatabase.user_withdraw(1, 10) == {:error, :not_enough_money_to_withdraw}
    assert UserDatabase.user_withdraw(2, 10) == {:error, :user_not_found}
    assert UserDatabase.user_deposit(1, -1) == {:error, :amount_not_positive}

    assert UserDatabase.add_user(3, "pepe") == {:ok, 3}
    assert UserDatabase.user_deposit(3, 1000) == :ok
    assert UserDatabase.user_deposit(3, 20) == :ok
    assert {:ok, %{balance: 1020}} = UserDatabase.user_get(3)
    assert UserDatabase.user_withdraw(3, 100) == :ok
    assert {:ok, %{balance: 920}} = UserDatabase.user_get(3)
    assert UserDatabase.user_deposit(3, 1000) == :ok
    assert {:ok, %{balance: 1920}} = UserDatabase.user_get(3)
  end

  test "get user" do
    assert UserDatabase.add_user(1, "dani") == {:ok, 1}
    assert UserDatabase.user_get(1) == {:ok, %User{name: "dani", id: 1, balance: 0}}
    assert UserDatabase.user_get(2) == {:error, :user_not_found}
    assert UserDatabase.user_deposit(1, 10) == :ok
    assert UserDatabase.user_get(1) == {:ok, %User{name: "dani", id: 1, balance: 10}}
  end
end
