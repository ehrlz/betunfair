defmodule Betunfair do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """
  @doc """
  Starts exchange. If name exists, recovers market.
  """
  def start_link(name) do
    # MySupervisor.start_link([name])
    CubDB.start_link("data/#{name}", name: Database)
    {:ok, name}
  end

  @doc """
  Shutdown running (if is running) exchange preserving data.
  """
  def stop() do
    #case Process.whereis(MySupervisor) do

    case Process.whereis(Database) do
      nil ->
        :noop

      pid ->
        case Process.alive?(pid) do
          true ->
            GenServer.stop(pid)

          false ->
            :noop
        end
    end

    :ok
  end

  @doc """
  Stops the exchange and removes persistent data. Initiates app for cleaning.
  """
  def clean(name) do
    :ok = stop()
    {:ok, _} = start_link(name)
    :ok = CubDB.clear(Database)
    :ok = stop()
    {:ok, name}
  end

  # -------------------- USER --------------------

  @spec user_create(binary(), binary()) :: {:error, atom} | {:ok, binary}
  def user_create(id, name) do
    new_user = %User{
      name: name,
      id: id
    }

    case CubDB.put_new(Database, {:user, id}, new_user) do
      {:error, :exists} ->
        {:error, :exists}

      _ ->
        {:ok, id}
    end
  end

  @spec user_deposit(binary(), integer()) :: {:error, atom} | :ok
  def user_deposit(id, amount) do
    CubDB.transaction(Database, fn tx ->
      tx = change_balance(tx, id, amount, :+)

      case tx do
        {:error, error} ->
          {:cancel, {:error, error}}

        tx ->
          {:commit, tx, :ok}
      end
    end)
  end

  @spec user_withdraw(binary(), integer()) :: {:error, atom} | :ok
  def user_withdraw(id, amount) do
    CubDB.transaction(Database, fn tx ->
      tx = change_balance(tx, id, amount, :-)

      case tx do
        {:error, error} ->
          {:cancel, {:error, error}}

        tx ->
          {:commit, tx, :ok}
      end
    end)
  end

  @spec user_get(binary()) :: :error | {:ok, User.t()}
  def user_get(id) do
    get(:user, id)
  end

  def user_bets(user_id) do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type_entry, _id}, _value} -> type_entry == :bet end)
      |> Stream.filter(fn {{_type_entry, _id}, value} -> value.user_id == user_id end)
      |> Stream.map(fn {{_type_entry, id}, _value} -> id end)
      |> Enum.to_list()

    {:ok, list}
  end

  # -------------------- MARKET --------------------

  @doc """
  Creates a market with the unique name, and a potentially longer desc.
  """
  @spec market_create(String.t(), String.t()) :: {:ok, binary}
  def market_create(name, description) do
    id = UUID.uuid1()

    new_market = %Market{
      id: id,
      name: name,
      description: description
    }

    CubDB.put(Database, {:market, id}, new_market)
    {:ok, id}
  end

  @spec market_list :: {:ok, list}
  def market_list() do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type_entry, _id}, _value} -> type_entry == :market end)
      |> Stream.map(fn {{_type_entry, id}, _value} -> id end)
      |> Enum.to_list()

    {:ok, list}
  end

  @spec market_list_active :: {:ok, list}
  def market_list_active() do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type_entry, _id}, _value} -> type_entry == :market end)
      |> Stream.filter(fn {{_type_entry, _id}, value} -> value.status == :active end)
      |> Stream.map(fn {{_type_entry, id}, _value} -> id end)
      |> Enum.to_list()

    {:ok, list}
  end

  # DEVUELVE TODO EL DINERO DE LAS APUESTA, match o unmatch
  @spec market_cancel(binary) :: :ok | {:error, atom}
  def market_cancel(market_id) do
    # selects all bets from market
    list_bets =
      CubDB.select(Database)
      |> Stream.filter(fn {{type, _id}, _value} -> type == :bet end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.market_id == market_id end)
      |> Stream.map(fn {{_type, _id}, value} -> value end)

    CubDB.transaction(Database, fn tx ->
      bet_tx =
        Enum.reduce(list_bets, tx, fn bet, tx ->
          # updates status all bets from market
          status_tx = update(tx, :bet, bet.id, :status, :market_cancelled)
          # returns unmatched and matched stake
          change_balance(status_tx, bet.user_id, bet.original_stake, :+)
        end)

      final_tx = update(bet_tx, :market, market_id, :status, :cancelled)
      {:commit, final_tx, :ok}
    end)
  end

  @spec market_freeze(binary) :: :ok | {:error, atom}
  def market_freeze(id) do
    CubDB.transaction(Database, fn tx ->
      final_tx = update(tx, :market, id, :status, :frozen)
      {:commit, final_tx, :ok}
    end)
  end

  @spec market_settle(binary(), boolean()) :: :ok | {:error, atom}
  def market_settle(id, result) do
    # selects all active bets from market
    list_active_bets =
      CubDB.select(Database)
      |> Stream.filter(fn {{type, _id}, _value} -> type == :bet end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.market_id == id end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.status == :active end)
      |> Stream.map(fn {{_type, _id}, value} -> value end)

    # declares with type of bet is the winner
    check =
      case result do
        true ->
          :back

        false ->
          :lay
      end

    # transaction
    CubDB.transaction(Database, fn tx ->
      # set market status
      market_tx = update(tx, :market, id, :status, {:settled, result})

      final_tx =
        Enum.reduce(list_active_bets, market_tx, fn bet, market_tx ->
          # all unmatched bet' stake return to user
          unmatched_tx =
            cond do
              bet.stake > 0 ->
                change_balance(market_tx, bet.user_id, bet.stake, :+)

              true ->
                market_tx
            end

          # all matched bet' stake return to winner user with interest
          matched_tx =
            case Enum.empty?(bet.matched_bets) do
              false ->
                cond do
                  # winner bet?
                  bet.bet_type == check ->
                    case check do
                      # depends on winner, formula changes
                      :back ->
                        change_balance(
                          unmatched_tx,
                          bet.user_id,
                          trunc((bet.original_stake - bet.stake) * (bet.odds / 100)),
                          :+
                        )

                      :lay ->
                        change_balance(
                          unmatched_tx,
                          bet.user_id,
                          trunc(
                            bet.original_stake - bet.stake +
                              trunc((bet.original_stake - bet.stake) / (bet.odds / 100 - 1))
                          ),
                          :+
                        )
                    end

                  true ->
                    unmatched_tx
                end

              true ->
                unmatched_tx
            end

          # sets the bet status
          update(matched_tx, :bet, bet.id, :status, {:market_settled, result})
        end)

      {:commit, final_tx, :ok}
    end)
  end

  @spec market_get(binary()) :: :error | {:ok, Market.t()}
  def market_get(id) do
    CubDB.fetch(Database, {:market, id})
  end

  @spec market_bets(binary) :: {:ok, Enumerable.t(binary())}
  def market_bets(market_id) do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type, _id}, _value} -> type == :bet end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.market_id == market_id end)
      |> Stream.map(fn {{_type, id}, _value} -> id end)
      |> Enum.to_list()

    {:ok, list}
  end

  @spec market_pending_backs(binary) ::
          {:error, atom} | {:ok, Enumerable.t({integer(), Enumerable.t(binary)})}
  def market_pending_backs(market_id) do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type, _id}, _value} -> type == :bet end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.market_id == market_id end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.status == :active end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.bet_type == :back end)
      |> Stream.map(fn {{_type, _id}, value} -> value end)
      |> Enum.sort({:asc, Bet})
      |> Enum.map(fn bet -> {bet.odds, bet.id} end)

    {:ok, list}
  end

  @spec market_pending_lays(binary) :: {:error, atom} | {:ok, Enumerable.t(binary)}
  def market_pending_lays(market_id) do
    list =
      CubDB.select(Database)
      |> Stream.filter(fn {{type, _id}, _value} -> type == :bet end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.market_id == market_id end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.status == :active end)
      |> Stream.filter(fn {{_type, _id}, value} -> value.bet_type == :lay end)
      |> Stream.map(fn {{_type, _id}, value} -> value end)
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
      {:ok, back_bet} = get(:bet, b_id)
      {:ok, lay_bet} = get(:bet, l_id)

      # back vision from lay stake
      real_lay_stake = trunc(lay_bet.stake / ((lay_bet.odds - 100) / 100))

      CubDB.transaction(Database, fn tx ->
        # stake changes
        stake_tx =
          cond do
            trunc(back_bet.stake * (back_bet.odds / 100)) - back_bet.stake >= real_lay_stake ->
              update(tx, :bet, b_id, :stake, back_bet.stake - real_lay_stake)
              |> update(:bet, l_id, :stake, 0)

            true ->
              update(tx, :bet, b_id, :stake, 0)
              |> update(
                :bet,
                l_id,
                :stake,
                lay_bet.stake - trunc(back_bet.stake * ((lay_bet.odds - 100) / 100))
              )
          end

        # update matched_bets
        bet_matched_bets = back_bet.matched_bets ++ [l_id]
        lay_matched_bets = lay_bet.matched_bets ++ [b_id]

        final_tx =
          update(stake_tx, :bet, b_id, :matched_bets, bet_matched_bets)
          |> update(:bet, l_id, :matched_bets, lay_matched_bets)

        {:commit, final_tx, :ok}
      end)

      {:ok, back_bet} = get(:bet, b_id)
      {:ok, lay_bet} = get(:bet, l_id)

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

  # -------------------- BET --------------------

  @spec bet_back(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_back(user_id, market_id, stake, odds) do
    bet_new(user_id, market_id, :back, stake, odds)
  end

  @spec bet_lay(binary(), binary(), integer(), integer()) :: {:ok, binary()} | {:error, atom()}
  def bet_lay(user_id, market_id, stake, odds) do
    bet_new(user_id, market_id, :lay, stake, odds)
  end

  defp bet_new(user_id, market_id, type, stake, odds) do
    id = UUID.uuid1()

    CubDB.transaction(Database, fn tx ->
      final_tx =
        case get_tx(tx, :market, market_id) do
          {:ok, market} ->
            case market.status do
              :active ->
                case get_tx(tx, :user, user_id) do
                  {:ok, user} ->
                    cond do
                      user.balance < stake ->
                        {:error, :insufficient_balance}

                      true ->
                        new_tx = change_balance(tx, user_id, stake, :-)

                        new_bet = %Bet{
                          id: id,
                          bet_type: type,
                          user_id: user_id,
                          market_id: market_id,
                          original_stake: stake,
                          stake: stake,
                          odds: odds,
                          date: DateTime.utc_now()
                        }

                        CubDB.Tx.put(new_tx, {:bet, id}, new_bet)
                    end

                  :error ->
                    {:error, :user_not_found}
                end

              _ ->
                {:error, :market_not_active}
            end

          :error ->
            {:error, :market_not_found}
        end

      case final_tx do
        {:error, error} ->
          {:cancel, {:error, error}}

        tx ->
          {:commit, tx, {:ok, id}}
      end
    end)
  end

  @spec bet_cancel(binary()) :: :ok | {:error, atom()}
  def bet_cancel(bet_id) do
    CubDB.transaction(Database, fn tx ->
      final_tx =
        case CubDB.Tx.fetch(tx, {:bet, bet_id}) do
          {:ok, bet} ->
            # returns unmatched stake

            unmatched_tx =
              case change_balance(tx, bet.user_id, bet.stake, :+) do
                {:error, _error} ->
                  tx

                return_tx ->
                  return_tx
              end

            if not Enum.empty?(bet.matched_bets) do
              # set unmatchable, but applies for later money returns
              money_tx =
                update(
                  unmatched_tx,
                  :bet,
                  bet_id,
                  :original_stake,
                  bet.original_stake - bet.stake
                )

              update(money_tx, :bet, bet_id, :stake, 0)
            else
              update(unmatched_tx, :bet, bet_id, :status, :cancelled)
            end

          :error ->
            {:error, :bet_not_found}
        end

      case final_tx do
        {:error, error} ->
          {:cancel, {:error, error}}

        tx ->
          {:commit, tx, :ok}
      end
    end)
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
    get(:bet, id)
  end

  @spec get(atom, binary) :: {:ok, User.t() | Market.t() | Bet.t()} | {:error, :not_found}
  @doc """
  Gets an entry from database.
  Returns error or {:ok, value}.
  """
  defp get(type_entry, id) do
    case CubDB.fetch(Database, {type_entry, id}) do
      :error ->
        {:error, :not_found}

      result ->
        result
    end
  end

  @spec get_tx(CubDB.Tx.t(), atom, binary) :: {:ok, any} | :error
  @doc """
  Gets an entry from transaction.
  Returns error or {:ok, value}.
  """
  defp get_tx(tx, type_entry, id) do
    CubDB.Tx.fetch(tx, {type_entry, id})
  end

  @spec update(CubDB.Tx.t(), atom, binary, atom, any) :: CubDB.Tx.t() | {:error, :not_found}
  @doc """
  Updates an entry in database.
  Returns new transaction with the operation.
  """
  defp update(tx, type_entry, id, key, value) do
    case CubDB.Tx.fetch(tx, {type_entry, id}) do
      :error ->
        {:error, :not_found}

      {:ok, data} ->
        new_data = Map.put(data, key, value)
        CubDB.Tx.put(tx, {type_entry, id}, new_data)
    end
  end

  # defp update_list(tx, type_entry, list, key, value) do
  #   Enum.map(list, fn id ->
  #     update(tx, type_entry, id, key, value)
  #   end)
  # end

  @spec change_balance(CubDB.Tx.t(), binary, non_neg_integer(), atom) ::
          CubDB.Tx.t()
          | {:error, :not_found | :amount_not_positive | :not_enough_money_to_withdraw}

  @doc """
  Adds/substracts amount to/from user_id balance.
  Returns new transaction with the operation.
  """
  defp change_balance(tx, user_id, amount, op) do
    cond do
      amount < 1 ->
        {:error, :amount_not_positive}

      true ->
        case CubDB.Tx.fetch(tx, {:user, user_id}) do
          :error ->
            {:error, :not_found}

          {:ok, user} ->
            # improve with "apply" and Kernel
            case op do
              :+ ->
                update(tx, :user, user_id, :balance, user.balance + amount)

              :- ->
                cond do
                  user.balance < amount ->
                    {:error, :not_enough_money_to_withdraw}

                  true ->
                    update(tx, :user, user_id, :balance, user.balance - amount)
                end
            end
        end
    end
  end
end
