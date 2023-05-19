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
end
