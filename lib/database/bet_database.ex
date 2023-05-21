defmodule BetDatabase do
  use GenServer

  @doc """
  Server that handles request from user data
  """

  @impl true
  def init(_init) do
    CubDB.start_link(data_dir: "data/bets", name: BetDB)
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
              {:error, :market_not_found}

            bet ->
              {:ok, bet}
          end
      end

    {:reply, reply, bet_db}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @spec bet_back(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_back(user_id, market_id, stake, odds) do
    new_bet = %Bet{
      bet_type: :back,
      user_id: user_id,
      market_id: market_id,
      original_stake: stake,
      remaining_stake: stake,
      odds: odds
    }

    GenServer.call(BetDB, {:new_bet, market_id, new_bet})
  end

  @spec bet_lay(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_lay(user_id, market_id, stake, odds) do
    new_bet = %Bet{
      bet_type: :lay,
      user_id: user_id,
      market_id: market_id,
      original_stake: stake,
      remaining_stake: stake,
      odds: odds
    }

    GenServer.call(BetDB, {:new_bet, market_id, new_bet})
  end

  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    GenServer.call(BetDB, {:bet_cancel, bet_id})
  end

  @spec bet_get(binary()) :: {:ok, map()} | {:error, atom()}
  def bet_get(bet_id) do
    GenServer.call(BetDB, {:bet_get, bet_id})
  end
end
