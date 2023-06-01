defmodule MySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(name) do
    children = [
      {UserDatabase, [name]},
      {MarketDatabase, [name]},
      {BetDatabase, [name]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def stop() do
    Supervisor.stop(__MODULE__)
  end

  def children() do
    Supervisor.count_children(__MODULE__)
  end
end
