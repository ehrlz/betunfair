defmodule Logic do
  @moduledoc """
  Project from Universidad Politécnica de Madrid
  """

  @doc """
  Starts exchange. If name exists, recovers market TODO
  """
  def start_link(name) do
    :world
  end

  @doc """
  Shutdown running exchange preserving data TODO
  """
  def stop() do
    :ok
  end

  @doc """
  Stops the exchange and removes persistent data TODO
  """
  def clean(name) do
    :world
  end
end
