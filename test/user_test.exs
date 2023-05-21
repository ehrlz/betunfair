defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  setup_all do
    UserDatabase.start_users([])
    :ok
  end

  test "clear" do
    UserDatabase.clear()
  end

  test "create_user" do
    assert UserDatabase.add_user(1,"dani") == {:ok,1}
    assert UserDatabase.add_user(1,"dani") == :error
  end
end
