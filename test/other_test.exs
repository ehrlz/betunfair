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

    assert {:ok, b1} = Betunfair.bet_back(u1, m1, 1000, 110)
    assert {:ok, b2} = Betunfair.bet_lay(u2, m1, 1000, 110)

    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
    assert is_error(Betunfair.user_get(u1))
    assert is_error(Betunfair.user_get(u2))
    assert is_error(Betunfair.market_get(m1))
    assert is_error(Betunfair.market_get(m2))
    assert is_error(Betunfair.bet_get(b1))
    assert is_error(Betunfair.bet_get(b2))
  end

  test "many users" do
    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
    assert {:ok, u1} = Betunfair.user_create("u1", "Daniel Milbradt")
    assert {:ok, u2} = Betunfair.user_create("u2", "Daniel Milbradt")
    assert {:ok, u3} = Betunfair.user_create("u3", "Daniel Milbradt")
    assert {:ok, u4} = Betunfair.user_create("u4", "Daniel Milbradt")
    assert {:ok, u5} = Betunfair.user_create("u5", "Daniel Milbradt")
    assert {:ok, u6} = Betunfair.user_create("u6", "Daniel Milbradt")
    assert {:ok, u7} = Betunfair.user_create("u7", "Daniel Milbradt")
    assert {:ok, u8} = Betunfair.user_create("u8", "Daniel Milbradt")
    assert {:ok, u9} = Betunfair.user_create("u9", "Daniel Milbradt")
    assert {:ok, u10} = Betunfair.user_create("u10", "Daniel Milbradt")
    assert {:ok, u11} = Betunfair.user_create("u11", "Daniel Milbradt")
    assert {:ok, u12} = Betunfair.user_create("u12", "Daniel Milbradt")
    assert {:ok, u13} = Betunfair.user_create("u13", "Daniel Milbradt")
    assert {:ok, u14} = Betunfair.user_create("u14", "Daniel Milbradt")
    assert {:ok, u15} = Betunfair.user_create("u15", "Daniel Milbradt")
    assert {:ok, u16} = Betunfair.user_create("u16", "Daniel Milbradt")
    assert is_ok(Betunfair.user_deposit(u1, 500))
    assert is_ok(Betunfair.user_deposit(u2, 500))
    assert is_ok(Betunfair.user_deposit(u3, 500))
    assert is_ok(Betunfair.user_deposit(u4, 500))
    assert is_ok(Betunfair.user_deposit(u5, 500))
    assert is_ok(Betunfair.user_deposit(u6, 500))
    assert is_ok(Betunfair.user_deposit(u7, 500))
    assert is_ok(Betunfair.user_deposit(u8, 500))
    assert is_ok(Betunfair.user_deposit(u9, 500))
    assert is_ok(Betunfair.user_deposit(u10, 500))
    assert is_ok(Betunfair.user_deposit(u11, 500))
    assert is_ok(Betunfair.user_deposit(u12, 500))
    assert is_ok(Betunfair.user_deposit(u13, 500))
    assert is_ok(Betunfair.user_deposit(u14, 500))
    assert is_ok(Betunfair.user_deposit(u15, 500))
    assert is_ok(Betunfair.user_deposit(u16, 500))
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u1)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u2)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u3)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u4)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u5)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u6)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u7)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u8)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u9)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u10)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u11)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u12)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u13)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u14)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u15)
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u16)

  end

  test "user1" do
    assert {:ok, _} = Betunfair.clean("otherdb")
    assert {:ok, _} = Betunfair.start_link("otherdb")
    assert {:ok, u1} = Betunfair.user_create("u1", "Daniel Milbradt")
    assert is_ok(Betunfair.user_deposit(u1, 500))
    assert {:ok, %{balance: 500}} = Betunfair.user_get(u1)
  end


  defp is_error(:error), do: true
  defp is_error({:error, _}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok, _}), do: true
  defp is_ok(_), do: false
end
