defmodule LogicTest do
  use ExUnit.Case
  doctest Logic

  setup_all do
    Logic.start_link("app")
    :ok
  end

  setup do
    {:ok, id} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    on_exit(fn -> Logic.clean("app") end)

    {:ok, market: id}
  end

  test "market get", state do
    assert Logic.market_get(state[:market]) ==
             {:ok, %Market{name: "Nadal-Nole", description: "Prueba mercado"}}
  end

  test "market get no desc" do
    {:ok, id} = Logic.market_create("Nadal-Nole", nil)
    assert Logic.market_get(id) == {:ok, %Market{name: "Nadal-Nole", description: nil}}
  end

  test "market list" do
    {:ok, _id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    {:ok, id_list} = Logic.market_list()
    assert length(id_list) == 3
  end

  test "market list active" do
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, _id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    assert Logic.market_cancel(id2) == :ok

    {:ok, id_list} = Logic.market_list_active()
    assert length(id_list) == 2
  end

  test "market list active 2", state do
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    Logic.market_cancel(id2)
    Logic.market_freeze(id3)

    {:ok, id_list} = Logic.market_list_active()
    assert id_list == [state[:market]]
  end

  test "market cancel", state do
    Logic.market_cancel(state[:market])

    {:ok, market} = Logic.market_get(state[:market])
    assert Map.get(market, :status) == :cancelled
  end

  test "market freeze", state do
    Logic.market_freeze(state[:market])

    {:ok, market} = Logic.market_get(state[:market])
    assert Map.get(market, :status) == :frozen
  end

  test "market settle", state do
    Logic.market_settle(state[:market], false)

    {:ok, market} = Logic.market_get(state[:market])
    assert Map.get(market, :status) == {:settled, false}
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

  # DATABASE
  test "get market", state do
    assert MarketDatabase.get_market(state[:market]) ==
             {:ok,
              %Market{
                name: "Nadal-Nole",
                description: "Prueba mercado",
                status: :active
              }}
  end

  test "list market" do
    id_list =
      for _n <- 1..4 do
        id = UUID.uuid1()
        MarketDatabase.put_market(id, "Prueba", "Desc. prueba")
        id
      end

    {:ok, list} = MarketDatabase.list_markets()
    assert length(list) == 5

    for id <- id_list do
      MarketDatabase.delete_market(id)
    end
  end

  test "put market" do
    market_id = UUID.uuid1()
    assert MarketDatabase.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    MarketDatabase.delete_market(market_id)
  end

  test "delete market" do
    market_id = UUID.uuid1()
    assert MarketDatabase.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    MarketDatabase.delete_market(market_id)
  end

  test "clear market" do
    assert MarketDatabase.clear_markets() == :ok

    {:ok, list} = MarketDatabase.list_markets()
    assert length(list) == 0
  end
end
