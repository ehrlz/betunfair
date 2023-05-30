defmodule OtherTests do
  use ExUnit.Case

  test "user_create_deposit_withdraw_get" do
    assert {:ok, _} = Betunfair.clean("testdb")
    assert {:ok, _} = Betunfair.start_link("testdb")
    assert {:ok, u1} = Betunfair.user_create("u1", "Daniel Milbradt")
    assert is_error(Betunfair.user_create("u1", "Daniel Milbradt"))
    assert is_ok(Betunfair.user_deposit(u1, 3500))
    assert is_ok(Betunfair.user_deposit(u1, 500))
    assert is_ok(Betunfair.user_withdraw(u1, 1000))
    assert is_error(Betunfair.user_withdraw(u1, -1))
    assert is_error(Betunfair.user_deposit(u1, -1))
    assert is_error(Betunfair.user_deposit(u1, 0))
    assert is_error(Betunfair.user_deposit("u11", 0))
    assert is_error(Betunfair.user_withdraw(u1, 5000))
    assert {:ok, %{balance: 3000}} = Betunfair.user_get(u1)
  end

  defp is_error(:error),do: true
  defp is_error({:error,_}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok,_}), do: true
  defp is_ok(_), do: false

end
