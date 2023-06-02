defmodule OtherTests do
  use ExUnit.Case

  test "user_create_deposit_withdraw_get" do
    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
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

  test "clear" do
    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
    assert {:ok, u1} = Betunfair.user_create("u1", "Daniel Milbradt")
    assert {:ok, u2} = Betunfair.user_create("u2", "Elías Herrero")
    assert is_ok(Betunfair.user_deposit(u1, 3500))
    assert is_ok(Betunfair.user_withdraw(u1, 1000))
    assert is_ok(Betunfair.user_deposit(u2, 3500))


    assert {:ok, m1} = Betunfair.market_create("inter gana", "UCL final")
    assert {:ok, m2} = Betunfair.market_create("nole gana RG", "paris tenis")

    assert {:ok, b1} = Betunfair.bet_back(u1,m1,1000,110)
    assert {:ok, b2} = Betunfair.bet_lay(u2,m1,1000,110)

    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
    assert is_error(Betunfair.user_get(u1))
    assert is_error(Betunfair.user_get(u2))
    assert is_error(Betunfair.market_get(m1))
    assert is_error(Betunfair.market_get(m2))
    assert is_error(Betunfair.bet_get(b1))
    assert is_error(Betunfair.bet_get(b2))
  end

  defp is_error(:error), do: true
  defp is_error({:error, _}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok, _}), do: true
  defp is_ok(_), do: false
end
