defmodule Logic do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """

  @doc """
  Starts exchange. If name exists, recovers market TODO
  """
  def start_link(name) do
    {:ok}
  end

  @doc """
  Shutdown running exchange preserving data TODO
  """
  def stop() do
    :ok
  end

  @doc """
  Stops the exchange and removes persistent data TODO
  """
  def clean(_name) do
    Database.clear_markets()
  end

  # MARKET
  @doc """
  Creates a market with the unique name, and a potentially longer desc.
  """
  def market_create(name, description) do
    Database.start_link([])
    id = UUID.uuid1()
    Database.put_market(id, name, description)
    {:ok, id}
  end

  def market_list() do
    list =
      Database.list_markets()
      |> Enum.map(fn {id, _market} -> id end)

    {:ok, list}
  end

  def market_list_active() do
    active_list =
      Database.list_markets()
      |> Enum.map(fn {id, market} ->
        Map.get(market, :active, true)
        id
      end)

    {:ok, active_list}
  end

  def market_cancel(id) do
    Database.put_market(id)
  end

  def market_get(id) do
    Database.get_market(id)
  end
end
