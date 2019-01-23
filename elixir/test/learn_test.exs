defmodule LearnTest do
  use ExUnit.Case
  doctest Learn

  test "add some numbers" do
    assert Learn.add() == 3
  end

  test "match assign" do
    x = 1
    assert x == 1
  end

  test "match both ways" do
    x = 1
    1 = x
  end

  test "fail match variable right" do
    x = 1
    1 = x
    assert_raise MatchError, fn ->
      2 = x
    end
  end
end
