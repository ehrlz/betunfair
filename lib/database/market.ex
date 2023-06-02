defmodule Market do
  defstruct id: nil, name: nil, description: nil, status: :active

  @type t() :: %Market{
          id: binary(),
          name: binary(),
          description: binary(),
          status: atom() | {atom(), boolean()}
        }
end
