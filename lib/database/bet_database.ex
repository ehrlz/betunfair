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
        {:new_bet, bet} ->
          bet_id = UUID.uuid1()
          CubDB.put(bet_db, bet_id, bet)
          {:ok, bet_id}

        # TODO cancelled market?
        {:bet_cancel, bet_id} ->
          case CubDB.get(bet_db, bet_id) do
            nil ->
              {:error, :bet_not_found}

            bet ->
              canc_bet = Map.put(bet, :status, :cancelled)
              CubDB.put(bet_db, bet_id, canc_bet)
              :ok
          end

        {:bet_get, bet_id} ->
          case CubDB.get(bet_db, bet_id) do
            nil ->
              {:error, :bet_not_found}

            bet ->
              {:ok, bet}
          end

        {:list_bets, market_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.market_id == market_id end)

        {:list_by_market, market_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.market_id == market_id end)

        {:list_by_user, user_id} ->
          CubDB.select(bet_db)
          |> Enum.filter(fn {_id, bet} -> bet.user_id == user_id end)

        :clear ->
          CubDB.clear(bet_db)
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
          {:ok, binary()} | {:error, atom()}
  def new_bet(user_id, market_id, type, stake, odds) do
    new_bet = %Bet{
      bet_type: type,
      user_id: user_id,
      market_id: market_id,
      original_stake: stake,
      remaining_stake: stake,
      odds: odds,
      date: DateTime.utc_now()
    }

    GenServer.call(BetDatabase, {:new_bet, new_bet})
  end

  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    GenServer.call(BetDatabase, {:bet_cancel, bet_id})
  end

  @spec bet_get(binary()) :: {:ok, map()} | {:error, atom()}
  def bet_get(bet_id) do
    GenServer.call(BetDatabase, {:bet_get, bet_id})
  end

  def list_bets(market_id) do
    GenServer.call(BetDatabase, {:list_bets, market_id})
  end

  def list_bets_by_market(market_id) do
    GenServer.call(BetDatabase, {:list_by_market, market_id})
  end

  def list_bets_by_user(user_id) do
    GenServer.call(BetDatabase, {:list_by_user, user_id})
  end

  def consume_stake(bet_id) do
    GenServer.call(BetDatabase, {:consume_stake, bet_id})
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
    case GenServer.whereis(MarketDatabase) do
      nil ->
        {:error, :exchange_not_deployed}

      pid ->
        GenServer.stop(pid)
        :ok
    end
  end
end
