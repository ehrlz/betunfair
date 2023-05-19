defmodule UserDatabase do
  use GenServer

  @doc """
  Server that handles request from user data
  """

  @impl true
  def init(_init) do
    CubDB.start_link(data_dir: "data/users")
  end

  @impl true
  def handle_call(op, _from, db_users) do
    reply =
      case op do
        nil -> :noop
      end

    {:reply, reply, db_users}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client
end
