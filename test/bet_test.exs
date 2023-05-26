defmodule BetTest do
  use ExUnit.Case
  doctest Logic

  setup_all do
    :ok
  end

  setup do
    Logic.clean("app")
    Logic.start_link("app")
    :ok
  end

  # TODO bet tests
  # BETS
  test "back bet" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")

    assert Logic.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Logic.bet_back(user_id, market_id, 100, 1.1)


    {:ok, bet} = Logic.bet_get(id)
    assert bet.user_id == user_id and
            bet.market_id == market_id and
            bet.bet_type == :back and
            bet.odds == 1.1 and
            bet.original_stake == 100 and
            bet.status == :active

    assert Logic.user_get(user_id) ==
             {:ok,
              %User{
                name: "Pepe Viyuela",
                id: "00001111A",
                balance: 900
              }}
  end

  test "lay bet" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Logic.bet_lay(user_id, market_id, 100, 1.1)

    {:ok, bet} = Logic.bet_get(id)
    assert bet.user_id == user_id and
            bet.market_id == market_id and
            bet.bet_type == :lay and
            bet.odds == 1.1 and
            bet.original_stake == 100

    assert Logic.user_get(user_id) ==
             {:ok,
              %User{
                name: "Pepe Viyuela",
                id: "00001111A",
                balance: 900
              }}
  end

  test "bet unk user" do
    {:ok, market_id} = Logic.market_create("Madrid-Atleti", "Prueba mercado")

    assert Logic.bet_lay("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
    assert Logic.bet_back("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
  end

  test "bet unk market" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    assert Logic.user_deposit(user_id, 1000) == :ok

    assert Logic.bet_lay(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
    assert Logic.bet_back(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
  end

  test "bet no money" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")

    {:error, :insufficient_balance} = Logic.bet_lay(user_id, market_id, 100, 1.1)
  end

  test "bet cancel" do
    {:ok, user_id} = Logic.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Logic.bet_lay(user_id, market_id, 100, 1.1)
    assert Logic.bet_cancel(id) == :ok

    {:ok, bet} = Logic.bet_get(id)
    assert bet.user_id == user_id and
            bet.market_id == market_id and
            bet.bet_type == :lay and
            bet.odds == 1.1 and
            bet.original_stake == 100 and
            bet.status == :cancelled
  end

  test "bet cancel unk" do
    assert Logic.bet_cancel(1) == {:error, :bet_not_found}
  end
end
