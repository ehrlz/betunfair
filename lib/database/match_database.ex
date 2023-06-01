defmodule MatchDatabase do
  use GenServer

  @doc """
  Process that handles matched info
  """

  @impl true
  def init(init) do
    [name] = init
    CubDB.start_link(data_dir: "data/#{name}/matched")
  end

  @impl true
  def handle_call(op, _from, db_matched) do
    reply =
      case op do
        {:get, match_id} ->
          CubDB.get(db_matched, match_id)

        :list ->
          CubDB.select(db_matched)
          |> Enum.to_list()

        {:list_by_market, market_id, op} ->
          list =
            CubDB.select(db_matched)
            |> Stream.map(fn {_id, match} -> match end)
            |> Stream.filter(fn match -> match.market_id == market_id end)

          case op do
            :all ->
              list

            :back ->
              Stream.map(list, fn match -> {match.back_id, match.value} end)

            :lay ->
              Stream.map(list, fn match -> {match.lay_id, match.value} end)
          end
          |> Enum.to_list()

        {:put, match_id, match} ->
          CubDB.put(db_matched, match_id, match)

        {:delete, match_id} ->
          CubDB.delete(match_id, match_id)

        :clear ->
          CubDB.clear(db_matched)

        :stop ->
          CubDB.stop(db_matched)
      end

    {:reply, reply, db_matched}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: MatchDatabase)
  end

  @spec get(binary()) :: map() | nil
  def get(match_id) do
    GenServer.call(MatchDatabase, {:get, match_id})
  end

  @spec list :: [Match.t()]
  def list() do
    GenServer.call(MatchDatabase, :list)
  end

  @spec list_by_market(binary(), atom()) :: [Match.t()]
  def list_by_market(market_id, op \\ :all) do
    case op do
      :all ->
        GenServer.call(MatchDatabase, {:list_by_market, market_id, :all})

      :back ->
        GenServer.call(MatchDatabase, {:list_by_market, market_id, :back})

      :lay ->
        GenServer.call(MatchDatabase, {:list_by_market, market_id, :lay})
    end
  end

  def put(market_id, back_id, lay_id, value) do
    id = UUID.uuid1()

    new_match = %Match{
      id: id,
      market_id: market_id,
      back_id: back_id,
      lay_id: lay_id,
      value: value
    }

    GenServer.call(MatchDatabase, {:put, id, new_match})
  end

  def delete(match_id) do
    GenServer.call(MatchDatabase, {:delete, match_id})
  end

  @doc """
  Removes persistent data and stops server if it's running
  """
  @spec clear() :: :ok
  def clear() do
    GenServer.call(MatchDatabase, :clear)
  end
end
