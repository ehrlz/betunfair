defmodule Match do
  defstruct id: nil,
            market_id: nil,
            back_id: nil,
            lay_id: nil,
            value: 0

  @type t() :: %Match{
          id: binary(),
          market_id: binary(),
          back_id: binary(),
          lay_id: binary(),
          value: integer()
        }
end
