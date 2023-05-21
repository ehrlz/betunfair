defmodule UserTest do
  use ExUnit.Case
  doctest UserDatabase

  # setup_all do
  #   UserDatabase.start_users([])
  #   :ok
  # end

  test "start" do
    Logic.start_users([])
    assert Logic.user_create("eloy","001") == {:ok}
  end
end
