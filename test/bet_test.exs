defmodule BetTest do
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

  # TODO
  test "back bet" do
  end

  test "lay bet" do
  end

  test "get bet" do
  end
end
