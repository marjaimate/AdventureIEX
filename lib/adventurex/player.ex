defmodule Adventurex.Player do
  use GenServer

  alias Adventurex.Dice

  # handle incoming actions and forward them to the gameplay
  #
  # handle battle
  # handle luck
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end
  def start_link(_, name), do: start_link(name)

  def skill(pid), do: GenServer.call({:global, pid}, {:get, :skill})
  def stamina(pid), do: GenServer.call({:global, pid}, {:get, :stamina})
  def luck(pid), do: GenServer.call({:global, pid}, {:get, :luck})

  def skill(pid, change), do: GenServer.cast({:global, pid}, {:put, :skill, change})
  def stamina(pid, change), do: GenServer.cast({:global, pid}, {:put, :stamina, change})
  def luck(pid, change), do: GenServer.cast({:global, pid}, {:put, :luck, change})

  # Restore your stamina by eating provisions
  # each provision restore 4 stamina points
  def eat(pid), do: GenServer.call({:global, pid}, :eat)

  # Get lucky !?
  # compare the player's luck score with 2 dice rolled
  def test_your_luck(player) do
    with luck_score <- luck(player)
    do
      luck(player, -1) # the cost of testing your luck
      lucky?(luck_score, Dice.roll + Dice.roll)
    end
  end

  def init(name) do
    {:ok, %{
      :name => name,
      :skill => Dice.roll + 6,
      :stamina => Dice.roll + Dice.roll + 12,
      :luck => Dice.roll + 6,
      :equipment => %{},
      :potions => %{},
      :provisions => 10,
      :jewels => %{},
      :gold => 0,
    }}
  end

  def handle_call({:get, attribute}, _from, state) do
    {:reply, state[:attribute], state}
  end
  def handle_call(:eat, _from, state = %{provisions: 0, stamina: s}) do
    IO.puts("Not enough provisions - can't restore stamina this time")
    {:reply, state[:provisions], state}
  end
  def handle_call(:eat, _from, state = %{provisions: p, stamina: s}) do
    IO.puts("That was a good meal! You restored 4 stamina points")
    {:reply, state[:provisions], %{state | provisions: p-1, stamina: s+4} }
  end

  def handle_cast({:put, attribute, change}, state) do
    {:noreply, Map.update!(state, attribute, &(&1 + change))}
  end

  ###### HELPERS ######
  defp lucky?(player_luck, luck_score) when player_luck >= luck_score, do: :lucky
  defp lucky?(_, _), do: :unlucky
end
