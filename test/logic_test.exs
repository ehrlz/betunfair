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

  test "market settle 2", state do
    Logic.market_settle(state[:market], true)

    {:ok, market} = Logic.market_get(state[:market])
    assert Map.get(market, :status) == {:settled, true}
  end

  # BETS
  test "back bet" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")

    {:ok, id} = Logic.bet_back(user_id, market_id, 100, 1.1)

    assert Logic.bet_get(id) ==
             {:ok,
              %Bet{
                bet_type: :back,
                user_id: user_id,
                market_id: market_id,
                odds: 1.1,
                original_stake: 100,
                remaining_stake: 100,
                matched_bets: [],
                status: :active
              }}
  end

  test "lay bet" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")

    {:ok, id} = Logic.bet_lay(user_id, market_id, 100, 1.1)

    assert Logic.bet_get(id) ==
             {:ok,
              %Bet{
                bet_type: :lay,
                user_id: user_id,
                market_id: market_id,
                odds: 1.1,
                original_stake: 100,
                remaining_stake: 100,
                matched_bets: [],
                status: :active
              }}
  end

  test "bet unk user" do
    {:ok, market_id} = Logic.market_create("Madrid-Atleti", "Prueba mercado")

    assert Logic.bet_lay("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
    assert Logic.bet_back("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
  end

  test "bet unk market" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")

    assert Logic.bet_lay(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
    assert Logic.bet_back(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
  end
end
