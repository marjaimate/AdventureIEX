defmodule Adventurex.Creature do
  use GenServer

  alias Adventurex.Dice

  # Attributes is a map with skill, stamina
  def start_link(name, attributes) do
    GenServer.start_link(__MODULE__, %{attributes | name: name}, name: {:global, name})
  end

  def name(pid), do: GenServer.call({:global, pid}, {:get, :name})
  def skill(pid), do: GenServer.call({:global, pid}, {:get, :skill})
  def stamina(pid), do: GenServer.call({:global, pid}, {:get, :stamina})

  def skill(pid, change), do: GenServer.call({:global, pid}, {:put, :skill, change})
  def stamina(pid, change), do: GenServer.call({:global, pid}, {:put, :stamina, change})

  # Simple init - just go with the state received
  def init(state), do: {:ok, state}

  def handle_call({:get, attribute}, _from, state) do
    {:reply, state[:attribute], state}
  end

  def handle_cast({:put, attribute, change}, state) do
    {:noreply, Map.update!(state, attribute, &(&1 + change))}
  end
end
