defmodule DatabaseTest do
  use ExUnit.Case
  doctest Database

  setup_all do
    Database.start_link([])
    :ok
  end

  setup do
    market_id = UUID.uuid1()
    Database.put_market(market_id, "Barcelona-Madrid", "Mercado prueba")

    on_exit(fn -> Database.delete_market(market_id) end)
    {:ok, market: market_id}
  end

  test "get market", state do
    assert Database.get_market(state[:market]) ==
             {:ok,
              %Market{
                name: "Barcelona-Madrid",
                description: "Mercado prueba",
                status: :active
              }}
  end

  test "list market" do
    id_list =
      for _n <- 1..4 do
        id = UUID.uuid1()
        Database.put_market(id, "Prueba", "Desc. prueba")
        id
      end

    {:ok, list} = Database.list_markets()
    assert length(list) == 5

    for id <- id_list do
      Database.delete_market(id)
    end
  end

  test "put market" do
    market_id = UUID.uuid1()
    assert Database.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    Database.delete_market(market_id)
  end

  test "delete market" do
    market_id = UUID.uuid1()
    assert Database.put_market(market_id, "Prueba", "Desc. prueba") == :ok
    Database.delete_market(market_id)
  end

  test "clear market" do
    assert Database.clear_markets() == :ok

    {:ok, list} = Database.list_markets()
    assert length(list) == 0
  end

  test "set unk status", state do
    assert Database.set_status_market(state[:market], :strange) == {:error, :status_not_accepted}
  end
end
