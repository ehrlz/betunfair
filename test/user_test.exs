defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  setup_all do
    Database.start_users([])
    :ok
  end

  test "add user", state do
    assert Database.add_user("eloy","001") == {:ok}
  end
end
