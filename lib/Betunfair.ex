defmodule Betunfair do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """
  alias CubDB.Btree.Enumerable

  @doc """
  Starts exchange. If name exists, recovers market TODO
  """
  def start_link(name) do
    MarketDatabase.start_link([name])
    UserDatabase.start_link([name])
    BetDatabase.start_link([name])
    MatchDatabase.start_link([name])
    {:ok, name}
  end

  @doc """
  Shutdown running exchange preserving data.
  TODO supervisor
  """
  def stop() do
    UserDatabase.stop()
    MarketDatabase.stop()
    BetDatabase.stop()
    MatchDatabase.stop()
  end

  @doc """
  Stops the exchange and removes persistent data.
  TODO supervisor
  """
  def clean(name) do
    UserDatabase.clear(name)
    MarketDatabase.clear(name)
    BetDatabase.clear(name)
    MatchDatabase.clear(name)
    {:ok, name}
  end

  # MARKET

  @doc """
  Creates a market with the unique name, and a potentially longer desc.
  """
  @spec market_create(String.t(), String.t()) :: {:ok, binary}
  def market_create(name, description) do
    id = MarketDatabase.put(name, description)
    {:ok, id}
  end

  @spec market_list :: {:ok, list}
  def market_list() do
    {:ok, MarketDatabase.list()}
  end

  @spec market_list_active :: {:ok, [binary()]}
  def market_list_active() do
    {:ok, MarketDatabase.list(:active)}
  end

  # DEVUELVE TODO EL DINERO DE LAS APUESTA, match o unmatch
  @spec market_cancel(binary) :: :ok | {:error, atom}
  def market_cancel(market_id) do
    BetDatabase.list_bets_by_market(market_id, :all)
    |> Enum.each(fn bet ->
      BetDatabase.bet_set_status(bet.id, :cancelled)
      # returns unmatched and matched stake
      UserDatabase.user_deposit(bet.user_id, bet.original_stake)
    end)

    market_set_status(market_id, :cancelled)
  end

  # TODO
  @spec market_freeze(binary) :: :ok | {:error, atom}
  def market_freeze(id) do
    market_set_status(id, :frozen)
  end

  # TODO unmatch returns to user after settle?
  @spec market_settle(binary(), boolean()) :: :ok | {:error, atom}
  def market_settle(id, result) do
    market_set_status(id, {:settled, result})

    # all unmatched bet' stake return to user
    BetDatabase.list_bets_by_market(id, :active)
    |> Enum.each(fn bet ->
      # IO.inspect(bet.stake, label: "UNMATCHED #{bet.type}")
      UserDatabase.user_deposit(bet.user_id, bet.stake)
    end)

    # matched bet' stake goes to winner
    check =
      case result do
        true ->
          :back

        false ->
          :lay
      end

    MatchDatabase.list_by_market(id, check)
    |> Enum.each(fn {bet_id, stake} ->
      bet = BetDatabase.bet_get(bet_id)
      real_odds = bet.odds / 100
      # IO.inspect(real_odds, label: "MATCHED odds #{bet.type}")
      # IO.inspect(stake, label: "MATCHED stake #{bet.type}")
      # IO.inspect(trunc(stake * real_odds), label: "MATCHED deposit")
      UserDatabase.user_deposit(bet.user_id, trunc(stake * real_odds))
    end)
  end

  defp market_set_status(id, status) do
    case MarketDatabase.get(id) do
      nil ->
        {:error, :market_not_found}

      market ->
        MarketDatabase.update(id, market.name, market.description, status)
    end
  end

  @spec market_get(binary) :: {:error, atom} | {:ok, Market.t()}
  def market_get(id) do
    case MarketDatabase.get(id) do
      nil ->
        {:error, :market_not_found}

      market ->
        {:ok, market}
    end
  end

  # TODO comprobar lo que devuelve en caso de error ( {:ok, :error}? )
  @spec market_bets(binary) :: {:ok, [binary()]}
  def market_bets(market_id) do
    list = BetDatabase.list_bets_by_market(market_id)

    {:ok, list}
  end

  @spec market_pending_backs(binary) ::
          {:error, atom} | {:ok, Enumerable.t({integer(), Enumerable.t(binary)})}
  def market_pending_backs(market_id) do
    list =
      BetDatabase.list_bets_by_market(market_id, :active)
      |> Enum.filter(fn bet -> bet.type == :back end)
      |> Enum.sort({:asc, Bet})
      |> Enum.map(fn bet -> {bet.odds, bet.id} end)

    {:ok, list}
  end

  @spec market_pending_lays(binary) :: {:error, atom} | {:ok, Enumerable.t(binary)}
  def market_pending_lays(market_id) do
    list =
      BetDatabase.list_bets_by_market(market_id, :active)
      |> Stream.filter(fn bet -> bet.type == :lay end)
      |> Enum.sort({:desc, Bet})
      |> Enum.map(fn bet -> {bet.odds, bet.id} end)

    {:ok, list}
  end

  @spec market_match(binary) :: :ok
  def market_match(market_id) do
    {:ok, pending_backs} = market_pending_backs(market_id)
    {:ok, pending_lays} = market_pending_lays(market_id)

    iterate_order_books(pending_backs, pending_lays)
    :ok
  end

  # Stops iterating if one list is empty
  defp iterate_order_books([], _) do
  end

  defp iterate_order_books(_, []) do
  end

  defp iterate_order_books(backs, lays) do
    # IO.inspect(backs)
    # IO.inspect(lays)
    [{b_odds, b_id} | _] = backs

    [{l_odds, l_id} | _] = lays

    # potential match
    if b_odds <= l_odds do
      back_bet = BetDatabase.bet_get(b_id)
      lay_bet = BetDatabase.bet_get(l_id)

      # IO.inspect(BetDatabase.bet_get(b_id))
      # IO.inspect(BetDatabase.bet_get(l_id))
      # back vision from lay stake
      real_lay_stake = trunc(lay_bet.stake / ((lay_bet.odds - 100) / 100))

      cond do
        trunc(back_bet.stake * (back_bet.odds / 100)) - back_bet.stake >= real_lay_stake ->
          # IO.inspect(lay_bet.stake, label: "lay stake")
          # IO.inspect(real_lay_stake, label: "formula lay stake")
          BetDatabase.update(b_id, :stake, back_bet.stake - real_lay_stake)
          BetDatabase.update(l_id, :stake, 0)
          # stores matched bets
          MatchDatabase.put(back_bet.market_id, b_id, l_id, real_lay_stake)

        true ->
          # IO.inspect(back_bet.stake, label: "back stake")
          BetDatabase.update(b_id, :stake, 0)

          BetDatabase.update(
            l_id,
            :stake,
            lay_bet.stake - trunc(back_bet.stake * ((lay_bet.odds - 100) / 100))
          )

          # stores matched bets
          MatchDatabase.put(back_bet.market_id, b_id, l_id, back_bet.stake)
      end

      back_bet = BetDatabase.bet_get(b_id)
      lay_bet = BetDatabase.bet_get(l_id)
      # IO.inspect(BetDatabase.bet_get(b_id))
      # IO.inspect(BetDatabase.bet_get(l_id))

      # removes empty
      new_backs =
        cond do
          back_bet.stake == 0 ->
            [_h | t] = backs
            t

          true ->
            backs
        end

      new_lays =
        cond do
          lay_bet.stake == 0 ->
            [_h | t] = lays
            t

          true ->
            lays
        end

      iterate_order_books(new_backs, new_lays)
    end
  end

  # BET

  @spec bet_back(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_back(user_id, market_id, stake, odds) do
    bet_new(user_id, market_id, :back, stake, odds)
  end

  @spec bet_lay(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_lay(user_id, market_id, stake, odds) do
    # stake represents money to cover from back
    bet_new(user_id, market_id, :lay, stake, odds)
  end

  defp bet_new(user_id, market_id, type, stake, odds) do
    case MarketDatabase.get(market_id) do
      nil ->
        {:error, :market_not_found}

      market ->
        case market.status do
          :active ->
            case UserDatabase.user_get(user_id) do
              {:error, :user_not_found} ->
                {:error, :user_not_found}

              {:ok, user} ->
                cond do
                  user.balance < stake ->
                    {:error, :insufficient_balance}

                  true ->
                    UserDatabase.user_withdraw(user_id, stake)
                    id = BetDatabase.new_bet(user_id, market_id, type, stake, odds)
                    {:ok, id}
                end
            end

          _ ->
            {:error, :market_not_active}
        end
    end
  end

  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    bet = BetDatabase.bet_get(bet_id)

    case bet do
      nil ->
        {:error, :bet_not_found}

      bet ->
        # only unmatched stake
        UserDatabase.user_deposit(bet.user_id, bet.stake)
        BetDatabase.bet_set_status(bet_id, :cancelled)
    end
  end

  @spec bet_get(binary) ::
          {:error, atom}
          | {:ok,
             %{
               :id => binary,
               :bet_type => atom,
               :odds => integer,
               :stake => integer,
               :status => atom
             }}
  def bet_get(id) do
    case BetDatabase.bet_get(id) do
      nil ->
        {:error, :bet_not_found}

      bet ->
        {:ok,
         %{id: bet.id, bet_type: bet.type, stake: bet.stake, odds: bet.odds, status: bet.status}}
    end
  end

  # User
  @spec user_create(binary(), binary()) :: {:error, atom} | {:ok, binary}
  def user_create(id, name) do
    UserDatabase.add_user(id, name)
  end

  @spec user_deposit(binary(), integer()) :: {:error, atom} | :ok
  def user_deposit(id, amount) do
    UserDatabase.user_deposit(id, amount)
  end

  @spec user_withdraw(binary(), integer()) :: {:error, atom} | :ok
  def user_withdraw(id, amount) do
    UserDatabase.user_withdraw(id, amount)
  end

  @spec user_get(binary()) :: {:error, atom} | {:ok, map()}
  def user_get(id) do
    UserDatabase.user_get(id)
  end

  @spec user_bets(any) :: {:ok, [binary()]}
  def user_bets(user_id) do
    list = BetDatabase.list_bets_by_user(user_id)
    {:ok, list}
  end
end
