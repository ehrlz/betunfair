defmodule MarketTest do
  use ExUnit.Case
  doctest Betunfair

  setup do
    Betunfair.clean("testdb")
    Betunfair.start_link("testdb")
    :ok
  end

  test "" do
  end
end
