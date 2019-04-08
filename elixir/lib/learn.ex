defmodule Learn do
  @moduledoc """
  Documentation for Learn.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Learn.add()
      3

  """
  def add do
    1 + 2
  end

  def defarg(x, e \\ 2) do
    :math.pow(x, e)
  end

end
