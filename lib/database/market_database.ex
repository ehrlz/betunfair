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
          CubDB.get(db_markets, market_id)

        {:list, status} ->
          stream =
            CubDB.select(db_markets)
            |> Stream.map(fn {_id, market} -> market end)

          case status do
            nil ->
              stream

            status ->
              Stream.filter(stream, fn market -> market.status == status end)
          end
          |> Stream.map(fn market -> market.id end)
          |> Enum.to_list()

        {:put, name, description} ->
          id = UUID.uuid1()

          new_market = %Market{
            id: id,
            name: name,
            description: description,
            status: :active
          }

          CubDB.put(db_markets, id, new_market)
          id

        {:update, id, name, description, status} ->
          new_market = %Market{
            id: id,
            name: name,
            description: description,
            status: status
          }

          CubDB.put(db_markets, id, new_market)

        {:delete, market_id} ->
          CubDB.delete(db_markets, market_id)

        :clear ->
          entries =
            CubDB.select(db_markets)
            |> Stream.map(fn {id, _market} -> id end)
            |> Enum.to_list()

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

  @spec get(binary()) :: Market.t() | nil
  def get(market_id) do
    GenServer.call(MarketDatabase, {:get, market_id})
  end

  @spec list(nil | atom) :: [binary()]
  def list(status \\ nil) do
    GenServer.call(MarketDatabase, {:list, status})
  end

  @spec put(binary(), nil | binary()) :: binary()
  def put(name, description \\ nil) do
    GenServer.call(MarketDatabase, {:put, name, description})
  end

  @spec update(binary(), binary(), nil | binary(), atom()) :: :ok
  def update(id, name, description, status) do
    GenServer.call(MarketDatabase, {:update, id, name, description, status})
  end

  @spec delete(binary()) :: :ok
  def delete(market_id) do
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
