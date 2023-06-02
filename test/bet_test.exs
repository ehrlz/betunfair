defmodule BetTest do
  use ExUnit.Case
  doctest Betunfair

  setup do
    assert {:ok, _} = Betunfair.clean("betdb")
    assert {:ok, _} = Betunfair.start_link("betdb")
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

  test "bet update" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 300, 150)
    {:ok, id2} = Betunfair.bet_back(user_id, market_id, 150, 150)

    {:ok, bet} = Betunfair.bet_get(id)
    assert bet.stake == 300

    {:ok, bet2} = Betunfair.bet_get(id2)
    assert bet2.stake == 150
  end

  test "matched_bets" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    {:ok, market_id} = Betunfair.market_create("Nadal-Nole", "Prueba mercado")
    assert Betunfair.user_deposit(user_id, 1000) == :ok

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 300, 150)
    {:ok, id2} = Betunfair.bet_back(user_id, market_id, 150, 150)

    :ok = Betunfair.market_match(market_id)

    {:ok, %{id: ^id, bet_type: :lay, status: :active, matched_bets: [^id2]}} =
      Betunfair.bet_get(id)

    {:ok, %{id: ^id2, bet_type: :back, status: :active, matched_bets: [^id]}} =
      Betunfair.bet_get(id2)
  end

  test "matched_bets2" do
    {:ok, user_id} = Betunfair.user_create("00001111A", "Pepe Viyuela")
    assert Betunfair.user_deposit(user_id, 100_000) == :ok

    {:ok, market_id} = Betunfair.market_create("Nadal gana", "Prueba mercado")

    {:ok, id} = Betunfair.bet_lay(user_id, market_id, 300, 150)
    {:ok, id2} = Betunfair.bet_back(user_id, market_id, 150, 150)

    assert :ok = Betunfair.market_match(market_id)

    assert :ok = Betunfair.market_settle(market_id, true)
    assert {:ok, %{status: {:market_settled, true}}} = Betunfair.bet_get(id)
    assert {:ok, %{status: {:market_settled, true}}} = Betunfair.bet_get(id2)

    {:ok, market_id2} = Betunfair.market_create("Real Madrid pierde", "Prueba mercado")

    {:ok, id3} = Betunfair.bet_lay(user_id, market_id2, 300, 150)
    {:ok, id4} = Betunfair.bet_back(user_id, market_id2, 150, 150)

    assert :ok = Betunfair.market_match(market_id2)

    assert :ok = Betunfair.market_settle(market_id2, false)
    assert {:ok, %{status: {:market_settled, false}}} = Betunfair.bet_get(id3)
    assert {:ok, %{status: {:market_settled, false}}} = Betunfair.bet_get(id4)
  end
end
