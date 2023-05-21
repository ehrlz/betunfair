defmodule Logic do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """
  alias CubDB.Btree.Enumerable

  @doc """
  Starts exchange. If name exists, recovers market TODO
  """
  def start_link(_name) do
    MarketDatabase.start_link([])
    UserDatabase.start_users([])
    BetDatabase.start_link([])
    {:ok}
  end

  @doc """
  Shutdown running exchange preserving data TODO
  """
  def stop() do
    :ok
  end

  @doc """
  Stops the exchange and removes persistent data TODO
  """
  def clean(_name) do
    UserDatabase.clear()
    MarketDatabase.clear_markets()
    BetDatabase.clear()
  end

  # MARKET

  @doc """
  Creates a market with the unique name, and a potentially longer desc.
  """
  @spec market_create(String.t(), String.t()) :: {:ok, binary}
  def market_create(name, description) do
    id = UUID.uuid1()
    MarketDatabase.put_market(id, name, description)
    {:ok, id}
  end

  @spec market_list :: {:ok, list}
  def market_list() do
    {:ok, list} = MarketDatabase.list_markets()

    reply =
      list
      |> Enum.map(fn {id, _market} -> id end)

    {:ok, reply}
  end

  @spec market_list_active :: {:ok, list}
  def market_list_active() do
    {:ok, list} = MarketDatabase.list_markets()

    active_list =
      list
      |> Enum.filter(fn {_id, market} ->
        Map.get(market, :status) == :active
      end)
      |> Enum.map(fn {id, _market} -> id end)

    {:ok, active_list}
  end

  # TODO cancel each bet in market
  @spec market_cancel(binary) :: :ok | {:error, atom}
  def market_cancel(id) do
    MarketDatabase.set_status_market(id, :cancelled)
  end

  @spec market_freeze(binary) :: :ok | {:error, atom}
  def market_freeze(id) do
    MarketDatabase.set_status_market(id, :frozen)
  end

  # TODO settle each bet in market
  @spec market_settle(binary(), boolean()) :: :ok | {:error, atom}
  def market_settle(id, result) do
    MarketDatabase.set_status_market(id, {:settled, result})
  end

  @spec market_get(binary) :: {:error, atom} | {:ok, map}
  def market_get(id) do
    MarketDatabase.get_market(id)
  end

  @spec market_bets(binary) :: {:ok, [binary()]}
  def market_bets(market_id) do
    list = BetDatabase.list_bets_by_market(market_id)

    {:ok, list}
  end

  @spec market_pending_backs(binary) ::
          {:error, atom} | {:ok, Enumerable.t({integer(), binary()})}
  def market_pending_backs(market_id) do
    list =
      BetDatabase.list_bets_by_market(market_id)
      |> Enum.filter(fn {_id,bet} -> bet.status == :active and bet.bet_type == :back end)

    {:ok, list}
  end

  @spec market_pending_lays(binary) :: {:error, atom} | {:ok, Enumerable.t({integer(), binary()})}
  def market_pending_lays(market_id) do
    list =
      BetDatabase.list_bets_by_market(market_id)
      |> Enum.filter(fn {_id,bet} -> bet.status == :active and bet.bet_type == :lay end)

    {:ok, list}
  end

  #TODO
  def market_match(market_id) do

  end

  # BET

  @spec bet_back(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_back(user_id, market_id, stake, odds) do
    bet_new(user_id, market_id, :back, stake, odds)
  end

  @spec bet_lay(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_lay(user_id, market_id, stake, odds) do
    bet_new(user_id, market_id, :lay, stake, odds)
  end

  defp bet_new(user_id, market_id, type, stake, odds) do
    case MarketDatabase.get_market(market_id) do
      {:error, :not_found} ->
        {:error, :market_not_found}

      _ ->
        case UserDatabase.user_get(user_id) do
          {:error, :user_not_found} ->
            {:error, :user_not_found}

          {:ok, user} ->
            cond do
              user.balance < stake ->
                {:error, :insufficient_balance}

              true ->
                UserDatabase.user_withdraw(user_id, stake)
                BetDatabase.new_bet(user_id, market_id, type, stake, odds)
            end
        end
    end
  end

  # TODO match funcionality
  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    BetDatabase.bet_cancel(bet_id)
  end

  @spec bet_get(binary) :: {:error, atom} | {:ok, map}
  def bet_get(id) do
    BetDatabase.bet_get(id)
  end

  # User
  @spec user_create(binary(), binary()) :: {:error, atom} | {:ok, binary}
  def user_create(id, name) do
    UserDatabase.add_user(id, name)
  end

  # TODO amount negative
  @spec user_deposit(binary(), integer()) :: {:error, atom} | :ok
  def user_deposit(id, amount) do
    UserDatabase.user_deposit(id, amount)
  end

  @spec user_get(binary()) :: {:error, atom} | {:ok, map()}
  def user_get(id) do
    UserDatabase.user_get(id)
  end

  # TODO
  def user_bets(market_id) do
  end
end
