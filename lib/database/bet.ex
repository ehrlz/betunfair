defmodule Bet do
  defstruct id: nil,
            type: nil,
            user_id: nil,
            market_id: nil,
            odds: 0,
            original_stake: 0,
            stake: 0,
            matched_bets: [],
            status: :active,
            date: nil

  @doc """
  Orders bets for its odds. Calificates bet1 to bet2.
  """
  def compare(bet1, bet2) do
    cond do
      bet1.odds < bet2.odds ->
        :lt

      bet1.odds == bet2.odds ->
        Date.compare(bet1.date, bet2.date)

      true ->
        :gt
    end
  end
end
