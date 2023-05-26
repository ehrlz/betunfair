defmodule User do
  defstruct name: nil,
            id: nil,
            balance: 0

  @type t() :: %User{
          id: binary(),
          name: binary(),
          balance: integer()
        }
end
