defmodule Adventurex.Dice do
  @faces [1,2,3,4,5,6]
  def roll do
    @faces |> Enum.shuffle |> hd
  end
end
