defmodule MySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    [name] = arg

    children = [
      Supervisor.child_spec({CubDB, "data/#{name}"}, name: Database)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
