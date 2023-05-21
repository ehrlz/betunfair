defmodule BetDatabase do
  use GenServer

  @doc """
  Server that handles request to 1 market
  """

  @impl true
  def init(market_name) do
    CubDB.start_link(data_dir: "data/markets/#{market_name}", name: BetDatabase)
  end

  @impl true
  def handle_call(op, _from, db_bets) do
    reply =
      case op do
        {:get, bet_id} ->
          case CubDB.get(db_bets, bet_id) do
            nil -> {:error, :not_found}
            value -> {:ok, value}
          end
      end

    {:reply, reply, db_bets}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  def start_link(market_name) do
    GenServer.start_link(__MODULE__, market_name)
  end

  @spec bet_back(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_back(user_id, market_id, stake, odds) do
    GenServer.call(BetDatabase, {:new, :back, user_id, market_id, stake, odds})
  end

  @spec bet_lay(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_lay(user_id, market_id, stake, odds) do
    GenServer.call(BetDatabase, {:new, :lay, user_id, market_id, stake, odds})
  end

  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    GenServer.call(BetDatabase, {:cancel, bet_id})
  end

  @spec get_bet(binary()) :: {:ok, map()} | {:error, atom()}
  def get_bet(bet_id) do
    GenServer.call(BetDatabase, {:get, bet_id})
  end
end
