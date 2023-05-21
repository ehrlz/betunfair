defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  setup_all do
    UserDatabase.start_users([])
    :ok
  end


  test "create_user" do
    UserDatabase.clear()
    assert UserDatabase.add_user(1,"dani") == {:ok,1}
    assert UserDatabase.add_user(1,"dani") == :error
  end

  test "deposit and withdraw" do
    UserDatabase.clear()
    assert UserDatabase.add_user(1,"dani") == {:ok,1}
    assert UserDatabase.user_deposit(1,10) == :ok
    assert UserDatabase.user_withdraw(1,5) == :ok
    assert UserDatabase.user_withdraw(1,10) == {:error,:not_enough_money_to_withdraw}
  end

end
