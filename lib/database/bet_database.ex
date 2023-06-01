defmodule BetDatabase do
  use GenServer

  @doc """
  Server that handles request from bet data
  """

  @impl true
  def init(init) do
    [name] = init
    CubDB.start_link(data_dir: "data/#{name}/bets")
  end

  @impl true
  def handle_call(op, _from, bet_db) do
    reply =
      case op do
        {:new, bet} ->
          CubDB.put(bet_db, bet.id, bet)
          bet.id

        {:get, bet_id} ->
          CubDB.get(bet_db, bet_id)

        {:list_by_market, market_id, type, status} ->
          list_bets =
            CubDB.select(bet_db)
            |> Stream.map(fn {_id, bet} -> bet end)
            |> Stream.filter(fn bet -> bet.market_id == market_id end)

          list_type =
            case type do
              :all ->
                list_bets

              type ->
                Stream.filter(list_bets, fn bet -> bet.bet_type == type end)
            end

          case status do
            :all ->
              list_bets

            status ->
              Stream.filter(list_type, fn bet -> bet.status == status end)
          end
          |> Enum.to_list()

        {:list_by_user, user_id} ->
          CubDB.select(bet_db)
          |> Stream.map(fn {_id, bet} -> bet end)
          |> Stream.filter(fn bet -> bet.user_id == user_id end)
          |> Enum.to_list()

        {:update, bet_id, key, value} ->
          bet = CubDB.get(bet_db, bet_id)
          new_bet = Map.put(bet, key, value)
          CubDB.put(bet_db, bet_id, new_bet)

        :clear ->
          CubDB.clear(bet_db)
      end

    {:reply, reply, bet_db}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: BetDatabase)
  end

  @spec new_bet(binary(), binary(), atom(), integer(), integer()) ::
          {:ok, binary()}
  def new_bet(user_id, market_id, type, stake, odds) do
    new_bet = %Bet{
      id: UUID.uuid1(),
      bet_type: type,
      user_id: user_id,
      market_id: market_id,
      original_stake: stake,
      stake: stake,
      odds: odds,
      date: DateTime.utc_now()
    }

    GenServer.call(BetDatabase, {:new, new_bet})
  end

  @doc """
  Returns a bet with this id, or nil if is not found
  """
  @spec bet_get(binary()) :: Bet.t() | nil
  def bet_get(bet_id) do
    GenServer.call(BetDatabase, {:get, bet_id})
  end

  @doc """
  List bets from market with certain status or type
  """
  @spec list_bets_by_market(binary, atom, atom) :: [Bet.t()]
  def list_bets_by_market(market_id, type \\ :all, status \\ :all) do
    GenServer.call(BetDatabase, {:list_by_market, market_id, type, status})
  end

  @spec list_bets_by_user(binary) :: [Bet.t()]
  def list_bets_by_user(user_id) do
    GenServer.call(BetDatabase, {:list_by_user, user_id})
  end

  def update(bet_id, key, value) do
    GenServer.call(BetDatabase, {:update, bet_id, key, value})
  end

  @doc """
  Removes persistent data and stops server if it's running
  """
  def clear() do
    GenServer.call(BetDatabase, :clear)
  end
end
