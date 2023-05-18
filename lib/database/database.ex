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
          CubDB.get(db_markets, market_id)

        :list_markets ->
          CubDB.select(db_markets)
          |> Enum.to_list()

        {:put_market, market_id, name, description} ->
          new_market = %Market{name: name, description: description}
          CubDB.put(db_markets, market_id, new_market)

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

  def get_market(market_id) do
    GenServer.call(Database, {:get_market, market_id})
  end

  def list_markets() do
    GenServer.call(Database, :list_markets)
  end

  #REFACTOR
  def put_market(market_id, name, description) do
    GenServer.call(Database, {:put_market, market_id, name, description})
  end

  def delete_market(market_id) do
    GenServer.call(Database, {:delete_market, market_id})
  end

  def clear_markets() do
    GenServer.call(Database, :clear_markets)
  end
end
