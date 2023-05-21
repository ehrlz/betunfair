defmodule UserDatabase do
  use GenServer

  @doc """
  Server that handles request from user data
  """

  @impl true
  def init(_init) do
    {:ok, db_users} = CubDB.start_link(data_dir: "data/users")
    {:ok, db_users}
  end

  @impl true
  def handle_call(op, _from, db_users) do
    reply =
      case op do
        #add_user----------------------------
        {:add_user,id, name} ->

          if CubDB.get(db_users,id) == nil do
            new_user = %User{
            name: name,
            id: id,
            }
            CubDB.put(db_users,id,new_user)
            {:ok, id}
          else
           {:error,:user_already_exists}
          end

        #get----------------------------
        {:user_get,id} ->
          user = CubDB.get(db_users,id)
          if user != nil do
          {:ok, user}
          else
           {:error,:user_does_not_exist}
          end
        #deposit----------------------------

        {:user_deposit,id, amount} ->
          user = CubDB.get(db_users,id)
          if user != nil do
            total = user.balance + amount
            user = Map.put(user,:balance,total)
            CubDB.put(db_users,id,user)
          else
           {:error,:user_already_exists}
          end
        #withdraw----------------------------

        {:user_withdraw,id, amount} ->
          user = CubDB.get(db_users,id)
          if user == nil do
            {:error,:user_already_exists}
          else
            total = user.balance
            if total < amount do
           {:error,:not_enough_money_to_withdraw}
            else
            total = total - amount
            user = Map.put(user,:balance,total)
            CubDB.put(db_users,id,user)
            end
          end


        #clear----------------------------
        :clear ->CubDB.clear(db_users)

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
    GenServer.start_link(__MODULE__, default,name: UserDatabase)
  end


  def add_user(id,name) do
    GenServer.call(UserDatabase, {:add_user,id,name})
  end

  @spec user_deposit(any, any) :: any
  def user_deposit(id,amount) do
    GenServer.call(UserDatabase,{:user_deposit,id,amount})
  end

  def user_withdraw(id,amount) do
    GenServer.call(UserDatabase,{:user_withdraw,id,amount})
  end

  def user_get(id)do
    GenServer.call(UserDatabase,{:user_get,id})
  end

  def clear() do
    GenServer.call(UserDatabase,:clear)
  end


end
