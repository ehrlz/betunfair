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

        {:list, market_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.market_id == market_id end)

        {:list_by_market, market_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.market_id == market_id end)

        {:list_by_user, user_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.user_id == user_id end)

        {:consume_stake, bet_id, value} ->
          bet = CubDB.get(bet_db, bet_id)
          new_bet = Map.put(bet, :stake, bet.stake - value)
          CubDB.put(bet_db, bet_id, new_bet)

        :clear ->
          CubDB.clear(bet_db)
          CubDB.stop(bet_db)

        :stop ->
          CubDB.stop(bet_db)
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
      type: type,
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

  @spec list_bets(binary) :: [Bet.t()]
  def list_bets(market_id) do
    GenServer.call(BetDatabase, {:list, market_id})
  end

  @spec list_bets_by_market(binary) :: [Bet.t()]
  def list_bets_by_market(market_id) do
    GenServer.call(BetDatabase, {:list_by_market, market_id})
    |> Enum.map(fn {_id, bet} -> bet end)
  end

  @spec list_bets_by_user(binary) :: [Bet.t()]
  def list_bets_by_user(user_id) do
    GenServer.call(BetDatabase, {:list_by_user, user_id})
  end

  @spec consume_stake(binary, integer) :: :ok
  def consume_stake(bet_id, value) do
    GenServer.call(BetDatabase, {:consume_stake, bet_id, value})
  end

  @doc """
  Removes persistent data and stops server if it's running
  """
  def clear(name) do
    case GenServer.whereis(BetDatabase) do
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
  def stop() do
    case GenServer.whereis(BetDatabase) do
      nil ->
        {:error, :exchange_not_deployed}

      pid ->
        GenServer.call(BetDatabase, :stop)
        GenServer.stop(pid)
        :ok
    end
  end
end
