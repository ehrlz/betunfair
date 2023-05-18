defmodule LogicTest do
  use ExUnit.Case
  doctest Logic

  # Market
  test "market create" do
    {:ok, _id} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    Logic.clean("ex")
  end

  test "market get" do
    {:ok, id} = Logic.market_create("Nadal-Nole", "Prueba mercado")
    assert Logic.market_get(id) == %Market{name: "Nadal-Nole", description: "Prueba mercado"}
    Logic.clean("ex")
  end

  test "market get no desc" do
    {:ok, id} = Logic.market_create("Nadal-Nole", nil)
    assert Logic.market_get(id) == %Market{name: "Nadal-Nole", description: nil}
    Logic.clean("ex")
  end

  test "market list" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", nil)
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    assert Logic.market_list() == {:ok, [id1, id2, id3]}

    Logic.clean("ex")
  end

  test "market list active" do
    {:ok, id1} = Logic.market_create("Nadal-Nole", nil)
    {:ok, id2} = Logic.market_create("Barcelona-Madrid", nil)
    {:ok, id3} = Logic.market_create("CSKA-Estrella Roja", nil)

    assert Logic.market_list_active() == {:ok, [id1, id2, id3]}

    Logic.clean("ex")
  end
end
