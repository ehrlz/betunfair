defmodule FaultTolTest do
  use ExUnit.Case

  test "broken userdatabase" do
    assert {:ok, _} = Betunfair.clean("testdb")
    assert {:ok, _} = Betunfair.start_link("testdb")
    assert {:ok, _u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, _u2} = Betunfair.user_create("u2", "Maria Fernandez")
    assert true = Process.exit(Process.whereis(UserDatabase), :shutdown)
    assert {:ok, _} = Betunfair.user_get("u2")
  end
end
