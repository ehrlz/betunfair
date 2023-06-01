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

        # TODO cancelled market?
        {:set_status, bet_id, status} ->
          case CubDB.get(bet_db, bet_id) do
            nil ->
              {:error, :bet_not_found}

            bet ->
              canc_bet = Map.put(bet, :status, status)
              CubDB.put(bet_db, bet_id, canc_bet)
          end

        {:get, bet_id} ->
          CubDB.get(bet_db, bet_id)

        {:list_by_market, market_id, status} ->
          list_bets =
            CubDB.select(bet_db)
            |> Stream.map(fn {_id, bet} -> bet end)
            |> Stream.filter(fn bet -> bet.market_id == market_id end)

          case status do
            :all ->
              list_bets

            status ->
              Stream.filter(list_bets, fn bet -> bet.status == status end)
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

  @spec bet_set_status(binary(), atom() | {atom(), boolean()}) :: :ok | {:error, atom()}
  def bet_set_status(bet_id, status) do
    GenServer.call(BetDatabase, {:set_status, bet_id, status})
  end

  @spec bet_get(binary()) :: Bet.t() | nil
  def bet_get(bet_id) do
    GenServer.call(BetDatabase, {:get, bet_id})
  end

  @spec list_bets_by_market(binary, atom) :: [Bet.t()]
  def list_bets_by_market(market_id, status \\ :all) do
    GenServer.call(BetDatabase, {:list_by_market, market_id, status})
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
