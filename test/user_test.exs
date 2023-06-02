defmodule UserTest do
  use ExUnit.Case, async: false
  doctest Betunfair

  setup do
    assert {:ok, _} = Betunfair.clean("userdb")
    assert {:ok, _} = Betunfair.start_link("userdb")

    :ok
  end

  test "create_user" do
    assert Betunfair.user_create(1, "dani") == {:ok, 1}
    assert Betunfair.user_create(1, "dani") == {:error, :exists}
  end

  test "deposit and withdraw" do
    assert Betunfair.user_create(1, "dani") == {:ok, 1}
    assert Betunfair.user_deposit(1, 10) == :ok
    assert Betunfair.user_deposit(2, 10) == {:error, :not_found}
    assert {:ok, %{balance: 10}} = Betunfair.user_get(1)
    assert Betunfair.user_withdraw(1, 5) == :ok
    assert {:ok, %{balance: 5}} = Betunfair.user_get(1)
    assert Betunfair.user_withdraw(1, 10) == {:error, :not_enough_money_to_withdraw}
    assert Betunfair.user_withdraw(2, 10) == {:error, :not_found}
    assert Betunfair.user_deposit(1, -1) == {:error, :amount_not_positive}

    assert Betunfair.user_create(3, "pepe") == {:ok, 3}
    assert Betunfair.user_deposit(3, 1000) == :ok
    assert Betunfair.user_deposit(3, 20) == :ok
    assert {:ok, %{balance: 1020}} = Betunfair.user_get(3)
    assert Betunfair.user_withdraw(3, 100) == :ok
    assert {:ok, %{balance: 920}} = Betunfair.user_get(3)
    assert Betunfair.user_deposit(3, 1000) == :ok
    assert {:ok, %{balance: 1920}} = Betunfair.user_get(3)
  end

  test "get user" do
    assert Betunfair.user_create(1, "dani") == {:ok, 1}
    assert Betunfair.user_get(1) == {:ok, %User{name: "dani", id: 1, balance: 0}}
    assert Betunfair.user_get(2) == {:error, :not_found}
    assert Betunfair.user_deposit(1, 10) == :ok
    assert Betunfair.user_get(1) == {:ok, %User{name: "dani", id: 1, balance: 10}}
  end
end
