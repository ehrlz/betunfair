defmodule Bet do
  defstruct bet_type: nil,
            user_id: nil,
            market_id: nil,
            odds: 0,
            original_stake: 0,
            remaining_stake: 0,
            matched_bets: [],
            status: :active
end
