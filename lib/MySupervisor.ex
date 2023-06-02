defmodule MySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    children = [
      {UserDatabase, arg},
      {MarketDatabase, arg},
      {BetDatabase, arg}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
