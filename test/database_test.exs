defmodule DatabaseTest do
  use ExUnit.Case
  doctest Database

  setup_all do
    Database.start_link([])
    :ok
  end

  test "get market" do
    market_id = UUID.uuid1()
    Database.put_market(market_id, "Barcelona-Madrid", "Mercado prueba")

    assert Database.get_market(market_id) == %Market{
             name: "Barcelona-Madrid",
             description: "Mercado prueba",
             active: true,
             status: :active
           }

    Database.clear_markets()
  end

  test "list market" do
    for _n <- 1..5 do
      Database.put_market(UUID.uuid1(), "Prueba", "Desc. prueba")
    end

    assert length(Database.list_markets()) == 5

    Database.clear_markets()
  end

  test "put market" do
    market_id = UUID.uuid1()
    assert Database.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    Database.clear_markets()
  end

  test "delete market" do
    market_id = UUID.uuid1()
    assert Database.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    assert Database.delete_market(market_id) == :ok
  end

  test "clear market" do
    assert Database.clear_markets() == :ok
    assert length(Database.list_markets()) == 0
  end
end
