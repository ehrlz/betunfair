defmodule Database do
  use GenServer

  @doc """
  Returns a database that stores each market and other that stores each user
  """

  @impl true
  def init(_init) do
    {:ok, db_users} = CubDB.start_link(data_dir: "data/users")
    {:ok, db_markets} = CubDB.start_link(data_dir: "data/markets")
    {:ok, {db_users, db_markets}}
  end

  @impl true
  def handle_call(op, _from, {db_users, db_markets}) do
    reply =
      case op do
        {:get_market, market_id} ->
          case CubDB.get(db_markets, market_id) do
            nil -> {:error, :not_found}
            value -> {:ok, value}
          end

        :list_markets ->
          list =
            CubDB.select(db_markets)
            |> Enum.to_list()

          {:ok, list}

        {:put_market, market_id, name, description, status} ->
          new_market = %Market{
            name: name,
            description: description,
            status: status
          }

          CubDB.put(db_markets, market_id, new_market)

        {:put_market, market_id, market} ->
          CubDB.put(db_markets, market_id, market)

        {:delete_market, market_id} ->
          CubDB.delete(db_markets, market_id)

        :clear_markets ->
          entries =
            CubDB.select(db_markets)
            |> Enum.to_list()
            |> Enum.map(fn {id, _market} -> id end)

          CubDB.delete_multi(db_markets, entries)
      end

    {:reply, reply, {db_users, db_markets}}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  # Market
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: Database)
  end

  @spec get_market(binary()) :: {:ok, map()} | {:error, atom()}
  def get_market(market_id) do
    GenServer.call(Database, {:get_market, market_id})
  end

  @spec list_markets :: {:ok, [binary()]}
  def list_markets() do
    GenServer.call(Database, :list_markets)
  end

  @spec put_market(binary(), map()) :: :ok
  def put_market(market_id, market) when is_map(market) do
    GenServer.call(Database, {:put_market, market_id, market})
  end

  def put_market(market_id, name, description \\ nil, status \\ :active) do
    GenServer.call(Database, {:put_market, market_id, name, description, status})
  end

  @spec set_status_market(binary(), :active | :frozen | :cancelled | {:settled, boolean()}) ::
          :ok | {:error, atom()}
  def set_status_market(market_id, status) do
    case status do
      :active ->
        {:ok, market} = get_market(market_id)
        new_map = Map.put(market, :status, :active)
        put_market(market_id, new_map)

      :frozen ->
        {:ok, market} = get_market(market_id)
        new_map = Map.put(market, :status, :frozen)
        put_market(market_id, new_map)

      :cancelled ->
        {:ok, market} = get_market(market_id)
        new_map = Map.put(market, :status, :cancelled)
        put_market(market_id, new_map)

      {:settled, result} ->
        {:ok, market} = get_market(market_id)
        new_map = Map.put(market, :status, {:settled, result})
        put_market(market_id, new_map)

      _ ->
        {:error, :status_not_accepted}
    end
  end

  def delete_market(market_id) do
    GenServer.call(Database, {:delete_market, market_id})
  end

  def clear_markets() do
    GenServer.call(Database, :clear_markets)
  end
end
