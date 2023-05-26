defmodule MarketDatabase do
  use GenServer

  @doc """
  Returns a database that stores each market and other that stores each user
  """

  @impl true
  def init(init) do
    [name] = init
    CubDB.start_link(data_dir: "data/#{name}/markets")
  end

  @impl true
  def handle_call(op, _from, db_markets) do
    reply =
      case op do
        {:get, market_id} ->
          case CubDB.get(db_markets, market_id) do
            nil -> {:error, :not_found}
            value -> {:ok, value}
          end

        :list ->
          list =
            CubDB.select(db_markets)
            |> Enum.to_list()

          {:ok, list}

        {:put, market_id, market} ->
          CubDB.put(db_markets, market_id, market)

        {:delete, market_id} ->
          CubDB.delete(db_markets, market_id)

        :clear ->
          entries =
            CubDB.select(db_markets)
            |> Enum.to_list()
            |> Enum.map(fn {id, _market} -> id end)

          CubDB.delete_multi(db_markets, entries)
          CubDB.stop(db_markets)

        :stop ->
          CubDB.stop(db_markets)
      end

    {:reply, reply, db_markets}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  # Market
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: MarketDatabase)
  end

  @spec get_market(binary()) :: {:ok, map()} | {:error, atom()}
  def get_market(market_id) do
    GenServer.call(MarketDatabase, {:get, market_id})
  end

  @spec list_markets :: {:ok, [binary()]}
  def list_markets() do
    GenServer.call(MarketDatabase, :list)
  end

  def put_market(market_id, name, description \\ nil, status \\ :active) do
    new_market = %Market{
      name: name,
      description: description,
      status: status
    }

    GenServer.call(MarketDatabase, {:put, market_id, new_market})
  end

  def delete_market(market_id) do
    GenServer.call(MarketDatabase, {:delete, market_id})
  end

  @doc """
  Removes persistent data and stops server if it's running
  """
  @spec clear(name :: binary()) :: :ok
  def clear(name) do
    case GenServer.whereis(MarketDatabase) do
      nil ->
        {:ok, pid} = start_link([name])
        GenServer.call(pid, :clear)
        GenServer.stop(pid)

      pid ->
        GenServer.call(pid, :clear)
        GenServer.stop(pid)
    end

    :ok
  end

  @doc """
  Stops server process
  """
  @spec stop() :: :ok | {:error, :exchange_not_deployed}
  def stop() do
    case GenServer.whereis(MarketDatabase) do
      nil ->
        {:error, :exchange_not_deployed}

      pid ->
        GenServer.call(MarketDatabase, :stop)
        GenServer.stop(pid)
        :ok
    end
  end
end
