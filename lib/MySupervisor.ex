defmodule MySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    [name] = arg

    children = [
      {CubDB, ["data/#{name}"]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def register_database() do
    children = Supervisor.which_children(__MODULE__)
    [{_,pid,_,_}] = children
    Process.register(pid,Database)
    :ok
  end
end
