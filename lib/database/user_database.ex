defmodule UserDatabase do
  use GenServer

  @doc """
  Server that handles request from user data
  """

  @impl true
  def init(_init) do
    CubDB.start_link(data_dir: "data/users", name: UserDatabase)
  end

  @impl true
  def handle_call(op, _from, db_users) do
    reply =
      case op do
        #add_user----------------------------
        {:add_user, id, name, user_id} ->
          if CubDB.get(db_users,id) != {:error,:not_found} do
            new_user = %User{
            user_id: user_id,
            name: name,
            id: id,
            }
          CubDB.put(db_users,id,new_user)
          else
            {:error}
          end
      end

    {:reply, reply, db_users}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  # Client

  @spec start_users(maybe_improper_list) :: :ignore | {:error, any} | {:ok, pid}
  def start_users(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end


  def add_user(id,name,user_id) do
    GenServer.call(UserDatabase, {:add_user, id,name,user_id})
  end


end
