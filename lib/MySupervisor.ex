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

  @spec stop :: :ok
  def stop() do
    :ok = Supervisor.stop(__MODULE__, :normal)
  end
end
