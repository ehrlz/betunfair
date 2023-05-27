defmodule Bet do
  defstruct id: nil,
            type: nil,
            user_id: nil,
            market_id: nil,
            odds: 0,
            original_stake: 0,
            stake: 0,
            status: :active,
            date: nil

  @type t() :: %Bet{
          id: binary(),
          type: atom(),
          user_id: binary(),
          market_id: binary(),
          odds: integer(),
          original_stake: integer(),
          stake: integer(),
          status: atom(),
          date: Date.t()
        }

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
