defmodule MarketTest do
  use ExUnit.Case
  doctest Betunfair

  setup do
    Betunfair.clean("testdb")
    Betunfair.start_link("testdb")
    :ok
  end

  test "market get" do
    {:ok, id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")

    assert Betunfair.market_get(id) ==
             {:ok, %Market{name: "Nadal-Nole", description: "Prueba mercado"}}
  end

  test "market get no desc" do
    {:ok, id} = Betunfair.market_create("Nadal-Nole", nil)
    assert Betunfair.market_get(id) == {:ok, %Market{name: "Nadal-Nole", description: nil}}
  end

  test "market list" do
    {:ok, _id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, _id2} = Betunfair.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Betunfair.market_create("CSKA-Estrella Roja", nil)

    {:ok, id_list} = Betunfair.market_list()
    assert length(id_list) == 3
  end

  test "market list active" do
    {:ok, _id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, id2} = Betunfair.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Betunfair.market_create("CSKA-Estrella Roja", nil)

    assert Betunfair.market_cancel(id2) == :ok

    {:ok, id_list} = Betunfair.market_list_active()
    assert length(id_list) == 2
  end

  test "market list active 2" do
    {:ok, id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, id2} = Betunfair.market_create("Barcelona-Madrid", nil)
    {:ok, id3} = Betunfair.market_create("CSKA-Estrella Roja", nil)

    Betunfair.market_cancel(id2)
    Betunfair.market_freeze(id3)

    {:ok, id_list} = Betunfair.market_list_active()
    assert id_list == [id1]
  end

  test "market cancel" do
    {:ok, id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.market_cancel(id1) == :ok

    {:ok, market} = Betunfair.market_get(id1)
    assert market.status == :cancelled
  end

  test "market freeze" do
    {:ok, id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.market_freeze(id1) == :ok

    {:ok, market} = Betunfair.market_get(id1)
    assert market.status == :frozen
  end

  test "market settle" do
    {:ok, id1} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.market_settle(id1, false) == :ok

    {:ok, market} = Betunfair.market_get(id1)
    assert market.status == {:settled, false}
  end

  test "market bets" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")

    assert Betunfair.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id} = Betunfair.bet_back(user_id, market_id, 100, 1.1)
    {:ok, _bet_id} = Betunfair.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id} = Betunfair.bet_back(user_id, market_id, 50, 1.1)

    {:ok, list} = Betunfair.market_bets(market_id)
    assert length(list) == 3
  end

  test "market pending backs" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")

    assert Betunfair.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id1} = Betunfair.bet_back(user_id, market_id, 100, 1.1)
    {:ok, bet_id2} = Betunfair.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id3} = Betunfair.bet_lay(user_id, market_id, 50, 1.1)
    {:ok, _bet_id4} = Betunfair.bet_back(user_id, market_id, 2, 1.1)
    {:ok, bet_id5} = Betunfair.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id6} = Betunfair.bet_lay(user_id, market_id, 2, 1.1)

    Betunfair.bet_cancel(bet_id2)
    Betunfair.bet_cancel(bet_id5)
    {:ok, list} = Betunfair.market_pending_backs(market_id)
    # 1 and 4
    assert length(list) == 2
  end

  test "market pending lays" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")

    assert Betunfair.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id1} = Betunfair.bet_back(user_id, market_id, 100, 1.1)
    {:ok, bet_id2} = Betunfair.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id3} = Betunfair.bet_lay(user_id, market_id, 50, 1.1)
    {:ok, _bet_id4} = Betunfair.bet_back(user_id, market_id, 2, 1.1)
    {:ok, bet_id5} = Betunfair.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id6} = Betunfair.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id7} = Betunfair.bet_lay(user_id, market_id, 2, 1.1)

    Betunfair.bet_cancel(bet_id2)
    Betunfair.bet_cancel(bet_id5)
    {:ok, list} = Betunfair.market_pending_lays(market_id)
    # 3, 6 and 7
    assert length(list) == 3
  end

  test "market pending backs sorted" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")
    assert Betunfair.user_deposit(user_id, 100_000) == :ok

    {:ok, bet_id1} = Betunfair.bet_back(user_id, market_id, 1000, 500)
    {:ok, bet_id2} = Betunfair.bet_back(user_id, market_id, 200, 220)
    {:ok, bet_id3} = Betunfair.bet_back(user_id, market_id, 50, 150)
    {:ok, bet_id4} = Betunfair.bet_back(user_id, market_id, 200, 1000)
    {:ok, bet_id5} = Betunfair.bet_back(user_id, market_id, 2000, 130)
    {:ok, bet_id6} = Betunfair.bet_back(user_id, market_id, 500, 400)

    {:ok, _bet_id7} = Betunfair.bet_lay(user_id, market_id, 2, 400)
    {:ok, _bet_id8} = Betunfair.bet_lay(user_id, market_id, 2, 500)

    {:ok, list} = Betunfair.market_pending_backs(market_id)

    assert list == [
             {130, bet_id5},
             {150, bet_id3},
             {220, bet_id2},
             {400, bet_id6},
             {500, bet_id1},
             {1000, bet_id4}
           ]
  end

  test "market pending lays sorted" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")

    assert Betunfair.user_deposit(user_id, 10000) == :ok

    {:ok, bet_id1} = Betunfair.bet_lay(user_id, market_id, 100, 500)
    {:ok, bet_id2} = Betunfair.bet_lay(user_id, market_id, 200, 220)
    {:ok, bet_id3} = Betunfair.bet_lay(user_id, market_id, 50, 150)
    {:ok, bet_id4} = Betunfair.bet_lay(user_id, market_id, 15, 1000)
    {:ok, bet_id5} = Betunfair.bet_lay(user_id, market_id, 24, 130)
    {:ok, bet_id6} = Betunfair.bet_lay(user_id, market_id, 8000, 400)

    {:ok, _bet_id7} = Betunfair.bet_back(user_id, market_id, 2, 4)
    {:ok, _bet_id8} = Betunfair.bet_back(user_id, market_id, 2, 5)

    {:ok, list} = Betunfair.market_pending_lays(market_id)

    assert list == [
             {1000, bet_id4},
             {500, bet_id1},
             {400, bet_id6},
             {220, bet_id2},
             {150, bet_id3},
             {130, bet_id5}
           ]
  end

  test "market pending lays sorted same odds" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Betunfair.user_create(1, "Pepe")

    assert Betunfair.user_deposit(user_id, 10000) == :ok

    {:ok, bet_id1} = Betunfair.bet_lay(user_id, market_id, 100, 500)
    {:ok, bet_id2} = Betunfair.bet_lay(user_id, market_id, 200, 220)
    {:ok, bet_id3} = Betunfair.bet_lay(user_id, market_id, 500, 150)
    {:ok, bet_id4} = Betunfair.bet_lay(user_id, market_id, 300, 110)
    {:ok, bet_id5} = Betunfair.bet_lay(user_id, market_id, 450, 1000)
    {:ok, bet_id6} = Betunfair.bet_lay(user_id, market_id, 620, 600)

    {:ok, list} = Betunfair.market_pending_lays(market_id)

    assert list == [
             {1000, bet_id5},
             {600, bet_id6},
             {500, bet_id1},
             {220, bet_id2},
             {150, bet_id3},
             {110, bet_id4}
           ]
  end
end
