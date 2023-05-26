defmodule Bet do
  defstruct bet_type: nil,
            user_id: nil,
            market_id: nil,
            odds: 0,
            original_stake: 0,
            remaining_stake: 0,
            matched_bets: [],
            status: :active

  @doc """
  Orders bets for its odds. Calificates bet1 to bet2.
  """
  def compare({_id1,bet1}, {_id2,bet2}) do
    cond do
      bet1.odds > bet2.odds -> :gt
      bet1.odds == bet2.odds -> :et
      true -> :lt
    end
  end
end
