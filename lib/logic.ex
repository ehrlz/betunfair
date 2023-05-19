defmodule Logic do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """

  @doc """
  Starts exchange. If name exists, recovers market TODO
  """
  def start_link(_name) do
    Database.start_link([])
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
  @spec market_create(String.t(), String.t()) :: {:ok, binary}
  def market_create(name, description) do
    id = UUID.uuid1()
    Database.put_market(id, name, description)
    {:ok, id}
  end

  @spec market_list :: {:ok, list}
  def market_list() do
    {:ok, list} = Database.list_markets()

    reply =
      list
      |> Enum.map(fn {id, _market} -> id end)

    {:ok, reply}
  end

  @spec market_list_active :: {:ok, list}
  def market_list_active() do
    {:ok, list} = Database.list_markets()

    active_list =
      list
      |> Enum.filter(fn {_id, market} ->
        Map.get(market, :status) == :active
      end)
      |> Enum.map(fn {id, _market} -> id end)

    {:ok, active_list}
  end

  @spec market_cancel(binary) :: :ok | {:error, atom}
  def market_cancel(id) do
    Database.set_status_market(id, :cancelled)
  end

  @spec market_freeze(binary) :: :ok | {:error, atom}
  def market_freeze(id) do
    Database.set_status_market(id, :frozen)
  end

  @spec market_settle(binary(), boolean()) :: :ok | {:error, atom}
  def market_settle(id, result) do
    Database.set_status_market(id, {:settled, result})
  end

  @spec market_get(binary) :: {:error, atom} | {:ok, map}
  def market_get(id) do
    Database.get_market(id)
  end
end
