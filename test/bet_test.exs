defmodule BetTest do
  use ExUnit.Case
  doctest Betunfair

  setup_all do
    :ok
  end

  setup do
    Betunfair.clean("app")
    Betunfair.start_link("app")
    :ok
  end

  # TODO bet tests
  # BETS
  test "back bet" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")

    assert Betunfair.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Betunfair.bet_back(user_id, market_id, 100, 1.1)

    assert {:ok, %{id: ^id, bet_type: :back, stake: 100, odds: 1.1, status: :active}} =
             Betunfair.bet_get(id)

    assert Betunfair.user_get(user_id) ==
             {:ok,
              %User{
                name: "Pepe Viyuela",
                id: "00001111A",
                balance: 900
              }}
  end

  test "lay bet" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.user_deposit(user_id, 20000) == :ok

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 100, 110)

    assert {:ok, %{id: ^id, bet_type: :lay, stake: 100, odds: 110, status: :active}} =
             Betunfair.bet_get(id)

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 5100, 140)

    assert {:ok, %{id: ^id, bet_type: :lay, stake: 5100, odds: 140, status: :active}} =
             Betunfair.bet_get(id)

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 8000, 120)

    assert {:ok, %{id: ^id, bet_type: :lay, stake: 8000, odds: 120, status: :active}} =
             Betunfair.bet_get(id)

    assert Betunfair.user_get(user_id) ==
             {:ok,
              %User{
                name: "Pepe Viyuela",
                id: "00001111A",
                balance: 6800
              }}
  end

  test "bet unk user" do
    {:ok, market_id} = Betunfair.market_create("Madrid-Atleti", "Prueba mercado")

    assert Betunfair.bet_lay("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
    assert Betunfair.bet_back("00001111A", market_id, 100, 1.1) == {:error, :user_not_found}
  end

  test "bet unk market" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    assert Betunfair.user_deposit(user_id, 1000) == :ok

    assert Betunfair.bet_lay(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
    assert Betunfair.bet_back(user_id, "asdasredqweasd", 100, 1.1) == {:error, :market_not_found}
  end

  test "bet no money" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")

    {:error, :insufficient_balance} = Betunfair.bet_lay(user_id, market_id, 100, 1.1)
  end

  test "bet cancel" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 100, 1.1)
    assert Betunfair.bet_cancel(id) == :ok

    {:ok, bet} = Betunfair.bet_get(id)
    assert bet.status == :cancelled

    assert {:ok, %{balance: 1000}} = Betunfair.user_get(user_id)
  end

  test "bet cancel unk" do
    assert Betunfair.bet_cancel(1) == {:error, :bet_not_found}
  end

  test "bet consume" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 150, 150)
    {:ok, id2} = Betunfair.bet_back(user_id, market_id, 150, 150)

    {:ok, bet} = Betunfair.bet_get(id)
    assert bet.stake == 150

    {:ok, bet2} = Betunfair.bet_get(id2)
    assert bet.stake == 150

    assert BetDatabase.consume_stake(id, 100) == :ok
    {:ok, bet} = Betunfair.bet_get(id)
    assert bet.stake == 50

    assert BetDatabase.consume_stake(id2, 100) == :ok
    {:ok, bet2} = Betunfair.bet_get(id2)
    assert bet2.stake == 50
  end
end
