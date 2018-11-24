defmodule Adventurex.Battle do
  # implement the battle sequence between 2 parties - a player and a creature
  # implement as a state machine
  # START
  # -----
  #   |
  # FIGHT
  # -----------------
  #  |      \       \
  # escape  player  creature
  #          wins    wins
  #

  use GenStateMachine, callback_mode: :state_functions
  alias Adventurex.Dice
  alias Adventurex.Player
  alias Adventurex.Creature

  # Public functions
  # initiate the battle with a creature
  def start_link(player, creature) do
    GenStateMachine.start(__MODULE__, {:fight, {creature, :start}})
  end

  # do the next round of the battle
  def next_round(battle, player), do: GenStateMachine.call(battle, {player, :round})
  def test_luck(battle, player), do: GenStateMachine.call(battle, {player, :luck})
  def escape(battle, player), do: GenStateMachine.call(battle, {player, :escape})
  def over(battle), do: GenStateMachine.cast(battle, :shutdown)

  ## States and transitions
  # fight x round
  def fight({:call, from}, {player, :round}, {creature, _}) do
    with player_attack_strength <- Dice.roll + Dice.roll + Player.skill(player),
         creature_attack_strength <- Dice.roll + Dice.roll + Creature.skill(creature)
    do
      result = compare(player_attack_strength, creature_attack_strength)
      {player1, creature1} = case result do
        :player_won_round ->
          # creature wounded, subtract 2 from creature stamina
          IO.puts("You have wounded the creature! -2 stamina points")
          {player, Creature.stamina(player, -2)}
        :creature_won_round ->
          IO.puts("The creature wounded you! -2 stamina points")
          # player wounded, subtract 2 from player stamina
          {Player.stamina(player, -2), creature}
        :blow_avoided ->
          IO.puts("You both missed")
          {player, creature}
      end
    end
    next = fight_over?(player, creature)
    {:next_state, next, {creature1, result}, {:reply, from, next}}
  end

  # fight x luck
  # depends on the previous round's outcome
  def fight({:call, from}, {player, :luck}, {creature, :player_won_round}) do
    creature1 = case Player.test_your_luck(player) do
      :lucky ->
        IO.puts("Serious damage to the creature! -2 stamina points")
        Creature.stamina(player, -2)
      :unlucky ->
        IO.puts("A mere gaze on the creature. restored 1 stamina point")
        Creature.stamina(player, 1)
    end
    next = fight_over?(player, creature)
    {:next_state, next, {creature1, :player_won_round}, {:reply, from, next}}
  end
  def fight({:call, from}, {player, :luck}, {creature, :creature_won_round}) do
    player1 = case Player.test_your_luck(player) do
      :lucky ->
        IO.puts("A mere gaze on you. restored 1 stamina point")
        Creature.stamina(player, 1)
      :unlucky ->
        IO.puts("Serious damage to you! -1 stamina points")
        Creature.stamina(player, -1)
    end
    next = fight_over?(player, creature)
    {:next_state, next, {creature1, :player_won_round}, {:reply, from, next}}
  end

  # fight x escape
  def fight({:call, from}, {player, :escape}, {creature, _}) do
    # Automatic wound from creature - "the price of cowardice"
    Player.stamina(player, -2)
    {:next_state, :player_escaped, creature, {:reply, from, :escaped}}
  end

  def handle_event({:call, from}, event, _state, data) do
    {:keep_state_and_data, [{:reply, from, data}]}
  end
  def handle_event(:cast, :shutdown, _, data) do
    {:stop, :normal, data}
  end

  # See who won based on the attack strength values
  defp compare(player_attack, creature_attack) when player_attack > creature_attack do
    :player_won_round
  end
  defp compare(strength, strength), do: :blow_avoided # Tie
  defp compare(_, _), do: :creature_won_round

  # Check if we have the fight over already?
  # if the player stamina is below 0 -> creature won
  # if the creature stamina is below 0 -> player won
  # else -> fight is still ongoing
  defp fight_over?(player, creature) do
    with player_stamina <- Player.stamina(player),
         creature_stamina < Creature.stamina(creature)
    do
      compare_stamina(player_stamina, creature_stamina)
    end
  end

  defp compare_stamina(player_stamina, creature_stamina) when player_stamina <= 0 do
    :creature_won
  end
  defp compare_stamina(player_stamina, creature_stamina) when creature_stamina <= 0 do
    :player_won
  end
  defp compare_stamina(_, _) do
    :fight
  end

  def terminate(:normal, _, creature) do
    IO.puts "Battle with #{Creature.name(creature)} finished"
  end
end
