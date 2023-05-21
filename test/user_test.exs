defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  setup_all do
    UserDatabase.start_users([])
    :ok
  end

  test "start" do
    assert UserDatabase.add_user("eloy","001",1) == :ok
  end
end
