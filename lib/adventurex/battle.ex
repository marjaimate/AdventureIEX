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

  def start_link(player, creature) do
    GenStateMachine.start(__MODULE__, {:fight, {creature, :start}})
  end

  ## States and transitions
  # fight x attack
  def fight({:call, from}, {player, :attack}, {creature, _}) do
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

    {:next_state, :fight, {creature1, result}, {:reply, from, player1}}
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
    {:next_state, :fight, {creature1, :player_won_round}, {:reply, from, player}}
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
    {:next_state, :fight, {creature1, :player_won_round}, {:reply, from, player}}
  end

  # fight x escape
  def fight({:call, from}, {player, :escape}, {creature, _}) do
    # Automatic wound from creature - "the price of cowardice"
    {:next_state, :over, {creature, :escaped}, {:reply, from, Player.stamina(player, -2)}}
  end

  # See who won based on the attack strength values
  defp compare(player_attack, creature_attack) when player_attack > creature_attack do
    :player_won_round
  end
  defp compare(strength, strength), do: :blow_avoided # Tie
  defp compare(_, _), do: :creature_won_round
end
