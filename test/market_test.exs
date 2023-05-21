defmodule LogicTest do
  use ExUnit.Case
  doctest Logic

  setup do
    Logic.clean("testdb")
    Logic.start_link("testdb")
    :ok
  end

  test "market get" do
    {:ok, id} = Logic.market_create("Nadal-Nole", "Prueba mercado")

    assert Logic.market_get(id) ==
             {:ok, %Market{name: "Nadal-Nole", description: "Prueba mercado"}}
  end

  test "market get no desc" do
    {:ok, id} = Logic.market_create("Nadal-Nole", nil)
    assert Logic.market_get(id) == {:ok, %Market{name: "Nadal-Nole", description: nil}}
  end

  test "market list" do
    {:ok, _id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, _id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    {:ok, id_list} = Logic.market_list()
    assert length(id_list) == 3
  end

  test "market list active" do
    {:ok, _id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    assert Logic.market_cancel(id2) == :ok

    {:ok, id_list} = Logic.market_list_active()
    assert length(id_list) == 2
  end

  test "market list active 2" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    Logic.market_cancel(id2)
    Logic.market_freeze(id3)

    {:ok, id_list} = Logic.market_list_active()
    assert id_list == [id1]
  end

  test "market cancel" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.market_cancel(id1) == :ok

    {:ok, market} = Logic.market_get(id1)
    assert market.status == :cancelled
  end

  test "market freeze" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.market_freeze(id1) == :ok

    {:ok, market} = Logic.market_get(id1)
    assert market.status == :frozen
  end

  test "market settle" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.market_settle(id1, false) == :ok

    {:ok, market} = Logic.market_get(id1)
    assert market.status == {:settled, false}
  end

  test "market bets" do
    {:ok, market_id} = Logic.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Logic.user_create(1, "Pepe")

    assert Logic.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id} = Logic.bet_back(user_id, market_id, 100, 1.1)
    {:ok, _bet_id} = Logic.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id} = Logic.bet_back(user_id, market_id, 50, 1.1)

    {:ok, list} = Logic.market_bets(market_id)
    assert length(list) == 3
  end

  test "market pending backs" do
    {:ok, market_id} = Logic.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Logic.user_create(1, "Pepe")

    assert Logic.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id1} = Logic.bet_back(user_id, market_id, 100, 1.1)
    {:ok, bet_id2} = Logic.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id3} = Logic.bet_lay(user_id, market_id, 50, 1.1)
    {:ok, _bet_id4} = Logic.bet_back(user_id, market_id, 2, 1.1)
    {:ok, bet_id5} = Logic.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id6} = Logic.bet_lay(user_id, market_id, 2, 1.1)

    Logic.bet_cancel(bet_id2)
    Logic.bet_cancel(bet_id5)
    {:ok, list} = Logic.market_pending_backs(market_id)
    # 1 and 4
    assert length(list) == 2
  end

  test "market pending lays" do
    {:ok, market_id} = Logic.market_create("Madrid-Olympiakos", "Prueba")
    {:ok, user_id} = Logic.user_create(1, "Pepe")

    assert Logic.user_deposit(user_id, 1000) == :ok
    {:ok, _bet_id1} = Logic.bet_back(user_id, market_id, 100, 1.1)
    {:ok, bet_id2} = Logic.bet_back(user_id, market_id, 200, 1.1)
    {:ok, _bet_id3} = Logic.bet_lay(user_id, market_id, 50, 1.1)
    {:ok, _bet_id4} = Logic.bet_back(user_id, market_id, 2, 1.1)
    {:ok, bet_id5} = Logic.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id6} = Logic.bet_lay(user_id, market_id, 2, 1.1)
    {:ok, _bet_id7} = Logic.bet_lay(user_id, market_id, 2, 1.1)

    Logic.bet_cancel(bet_id2)
    Logic.bet_cancel(bet_id5)
    {:ok, list} = Logic.market_pending_lays(market_id)
    # 3, 6 and 7
    assert length(list) == 3
  end
end
