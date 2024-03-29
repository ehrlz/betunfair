defmodule FaultTolTest do
  use ExUnit.Case

  setup do
    assert {:ok, _} = Betunfair.clean("ft_test")
    assert {:ok, _} = Betunfair.start_link("ft_test")
    :ok
  end

  test "recover userdatabase" do
    {:ok, _u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
    {:ok, _u2} = Betunfair.user_create("u2", "Maria Fernandez")

    assert_raise ArithmeticError, fn -> Betunfair.user_deposit("u1", 1 / 0) end

    assert {:ok, _} = Betunfair.user_get("u2")
  end

  test "recover marketdatabase" do
    {:ok, m1} = Betunfair.market_create("real madrid wins", "prueba")
    {:ok, _u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
    {:ok, _u2} = Betunfair.user_create("u2", "Maria Fernandez")

    assert_raise ArithmeticError, fn -> Betunfair.market_get(1 / 0) end

    assert {:ok, _} = Betunfair.market_get(m1)
  end

  test "recover betdatabase" do
    {:ok, u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
    Betunfair.user_deposit(u1, 200_000)
    {:ok, m1} = Betunfair.market_create("real madrid wins", "prueba")
    {:ok, b1} = Betunfair.bet_back("u1", m1, 100, 120)

    assert_raise ArithmeticError, fn -> Betunfair.bet_back("u1", m1, 1 / 0, 120) end

    assert {:ok, _} = Betunfair.bet_get(b1)
  end

  test "recover all" do
    {:ok, u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
    {:ok, _u2} = Betunfair.user_create("u2", "Maria Fernandez")
    Betunfair.user_deposit(u1, 200_000)
    {:ok, m1} = Betunfair.market_create("real madrid wins", "prueba")
    {:ok, b1} = Betunfair.bet_back("u1", m1, 100, 120)

    assert_raise ArithmeticError, fn -> Betunfair.user_deposit("u1", 1 / 0) end
    assert_raise ArithmeticError, fn -> Betunfair.market_get(1 / 0) end
    assert_raise ArithmeticError, fn -> Betunfair.bet_back("u1", m1, 1 / 0, 120) end

    assert {:ok, _} = Betunfair.user_get("u2")
    assert {:ok, _} = Betunfair.market_get(m1)
    assert {:ok, _} = Betunfair.bet_get(b1)
  end


  # test "concurrency" do
  #   {:ok, u1} = Betunfair.user_create("u1", "Francisco Gonzalez")
  #   {:ok, m1} = Betunfair.market_create("real madrid wins", "prueba")

  #   :ok = Betunfair.user_deposit(u1,100000000000)

  #   for _ <- 1..1000  do
  #     Betunfair.bet_back(u1,m1,:rand.uniform(1000),:random.uniform(2))
  #   end

  #   for x <- 1..1000 do
  #     Process.spawn(fn ->
  #       init = DateTime.utc_now()
  #       {:ok, list} = Betunfair.market_pending_backs(m1)
  #       time_lapsed = DateTime.diff(init,DateTime.utc_now())
  #       IO.inspect(time_lapsed)
  #     end, [])
  #   end
  # end
end
