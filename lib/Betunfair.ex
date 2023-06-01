defmodule Betunfair do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """

  @doc """
  Starts exchange. If name exists, recovers market. If market is up, nothing is done
  """
  def start_link(name) do
    options = [
      name: Betunfair.Supervisor,
      strategy: :one_for_one
    ]

    case DynamicSupervisor.start_link(options) do
      {:ok, _} ->
        {:ok, _pid} = DynamicSupervisor.start_child(Betunfair.Supervisor, {UserDatabase, [name]})

        {:ok, _pid} =
          DynamicSupervisor.start_child(Betunfair.Supervisor, {MarketDatabase, [name]})

        {:ok, _pid} = DynamicSupervisor.start_child(Betunfair.Supervisor, {BetDatabase, [name]})

        {:ok, name}

      error ->
        error
    end
  end

  @doc """
  Shutdown running exchange preserving data.
  """
  def stop() do
    DynamicSupervisor.stop(Betunfair.Supervisor)
  end

  @doc """
  Stops the exchange and removes persistent data. Initiates app for cleaning.
  """
  def clean(name) do
    case start_link(name) do
      {:ok, _} ->
        UserDatabase.clear()
        MarketDatabase.clear()
        BetDatabase.clear()

        :ok = stop()
        {:ok, name}

      {:error, {:already_started, _}} ->
        UserDatabase.clear()
        MarketDatabase.clear()
        BetDatabase.clear()

        :ok = stop()
        {:ok, name}

      other_error ->
        other_error
    end
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
    BetDatabase.list_bets_by_market(market_id)
    |> Enum.each(fn bet ->
      BetDatabase.update(bet.id, :status, :market_cancelled)
      # returns unmatched and matched stake
      UserDatabase.user_deposit(bet.user_id, bet.original_stake)
    end)

    market_set_status(market_id, :cancelled)
  end

  @spec market_freeze(binary) :: :ok | {:error, atom}
  def market_freeze(id) do
    market_set_status(id, :frozen)
  end

  @spec market_settle(binary(), boolean()) :: :ok | {:error, atom}
  def market_settle(id, result) do
    :ok = market_set_status(id, {:settled, result})

    # all unmatched bet' stake return to user
    BetDatabase.list_bets_by_market(id, :all, :active)
    |> Enum.each(fn bet ->
      # IO.inspect(bet.stake, label: "UNMATCHED stake #{bet.bet_type}")
      # IO.inspect(bet.original_stake, label: "ORIGINAL #{bet.bet_type}")

      if bet.stake > 0 do
        :ok = UserDatabase.user_deposit(bet.user_id, bet.stake)
      end
    end)

    # declares with type of bet is the winner
    check =
      case result do
        true ->
          :back

        false ->
          :lay
      end

    # all matched bet' stake return to user with interest
    BetDatabase.list_bets_by_market(id, check, :active)
    |> Enum.each(fn bet ->
      if not Enum.empty?(bet.matched_bets) do
        case check do
          # if back wins, benefits are played stake * odds
          :back ->
            :ok =
              UserDatabase.user_deposit(
                bet.user_id,
                trunc((bet.original_stake - bet.stake) * (bet.odds / 100))
              )

          # if back wins, benefits are played back stakes
          :lay ->
            :ok =
              UserDatabase.user_deposit(
                bet.user_id,
                bet.original_stake - bet.stake +
                  trunc((bet.original_stake - bet.stake) / (bet.odds / 100 - 1))
              )
        end
      end
    end)

    BetDatabase.list_bets_by_market(id, :all, :active)
    |> Enum.each(fn bet ->
      :ok = BetDatabase.update(bet.id, :status, {:market_settled, result})
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
      BetDatabase.list_bets_by_market(market_id, :back, :active)
      |> Enum.sort({:asc, Bet})
      |> Enum.map(fn bet -> {bet.odds, bet.id} end)

    {:ok, list}
  end

  @spec market_pending_lays(binary) :: {:error, atom} | {:ok, Enumerable.t(binary)}
  def market_pending_lays(market_id) do
    list =
      BetDatabase.list_bets_by_market(market_id, :lay, :active)
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

      # back vision from lay stake
      real_lay_stake = trunc(lay_bet.stake / ((lay_bet.odds - 100) / 100))

      cond do
        trunc(back_bet.stake * (back_bet.odds / 100)) - back_bet.stake >= real_lay_stake ->
          BetDatabase.update(b_id, :stake, back_bet.stake - real_lay_stake)
          BetDatabase.update(l_id, :stake, 0)

        true ->
          # IO.inspect(back_bet.stake, label: "back stake")
          BetDatabase.update(b_id, :stake, 0)

          BetDatabase.update(
            l_id,
            :stake,
            lay_bet.stake - trunc(back_bet.stake * ((lay_bet.odds - 100) / 100))
          )
      end

      # update matched_bets
      new_matched_bets = back_bet.matched_bets ++ [l_id]

      BetDatabase.update(
        b_id,
        :matched_bets,
        new_matched_bets
      )

      new_matched_bets = lay_bet.matched_bets ++ [b_id]

      BetDatabase.update(
        l_id,
        :matched_bets,
        new_matched_bets
      )

      back_bet = BetDatabase.bet_get(b_id)
      lay_bet = BetDatabase.bet_get(l_id)

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
        # returns unmatched stake
        UserDatabase.user_deposit(bet.user_id, bet.stake)

        if not Enum.empty?(bet.matched_bets) do
          # set unmatchable, but applies for later money returns
          BetDatabase.update(bet_id, :original_stake, bet.original_stake - bet.stake)
          BetDatabase.update(bet_id, :stake, 0)
        else
          BetDatabase.update(bet_id, :status, :cancelled)
        end
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
        # {:ok,
        # %{id: bet.id, bet_type: bet.bet_type, stake: bet.stake, odds: bet.odds, status: bet.status}}
        {:ok, Map.from_struct(bet)}
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
