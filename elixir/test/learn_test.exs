defmodule LearnTest do
  use ExUnit.Case
  doctest Learn

  alias Enum

  test "add some numbers" do
    assert Learn.add() == 3
  end

  test "rounding and truncating" do
    assert 4 * 5 == 20
    # multiplying integers gives integer
    assert 4 * 5 === 20
    # results of division is (always?) a float
    assert 4 * 5 / 2 !== 10

  end

  test "basic types" do
    assert is_number(1)
  end

  test "list basics" do
    list = [1, 2, 3, :barf, false]
    assert length(list) == 5
    assert_raise ArgumentError, fn ->
      # cannot subscript a list with an integer
      assert list[3] == :barf
    end
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

  test "tuple pattern matching" do
    {:ok, a, b} = {:ok, {:results}, 42}
    assert a == {:results}
    assert b == 42
    {:ok, {val}, b} = {:ok, {:results}, 42}
    assert val == :results
    assert b == 42
  end

  test "failed tuple matching" do
    assert_raise MatchError, fn ->
      {_a, _b, _c} = {:ok, 42}
    end
    assert_raise MatchError, fn ->
      {_a} = {:ok, 42}
    end
  end

  test "list pattern matching" do
    [:ok, a, b] = [:ok, [:results], 42]
    assert a == [:results]
    assert b == 42
    [:ok, [val], b] = [:ok, [:results], 42]
    assert val == :results
    assert b == 42
  end

  test "list head tail matching" do
    [head | tail] = [1, 2, 3]
    assert head == 1
    assert tail == [2, 3]
    [1 | tail] = [1, 2, 3]
    assert tail == [2, 3]
    [head | [2, 3]] = [1, 2, 3]
    assert head == 1
  end

  test "list head append" do
    list_a = [2, 3]
    list_b = [1 | list_a]
    assert list_b == [1, 2, 3]
  end

  test "pin operator" do
    x = 1
    ^x = 1
    assert_raise MatchError, fn ->
      ^x = 2
    end
  end

  test "pin operator longer" do
    [head | _tail] = [1, 2, 3]
    [^head | tail] = [1, 3, 5]
    assert tail == [3, 5]
    assert_raise MatchError, fn ->
      [^head | _tail] = [2, 3, 5]
    end
end

  test "keyword list" do
    kl = [a: 1, b: 2]
    assert is_list(kl)
    assert kl[:a] == 1
    assert kl[:b] == 2
  end

  test "append keyword list" do
    kl = [a: 1, b: 2]
    klb = kl ++ [c: 3]

    assert klb == [a: 1, b: 2, c: 3]

    # order matters: it really is just a list!
    assert klb != [c: 3, b: 2, a: 1]
  end

  test "append keyword list same key" do
    kl = [a: 1, b: 2]
    klb = kl ++ [b: 3]

    assert length(klb) == 3
    assert klb[:b] != 3
    assert klb == [a: 1, b: 2, b: 3]
  end

  test "prepend keyword list same key" do
    kl = [a: 1, b: 2]
    klb = [b: 3] ++ kl

    assert klb[:b] == 3
    assert klb == [b: 3, a: 1, b: 2]
  end

  test "with operator" do
    k = [a: 1, b: 2]
    with [a: 1, b: x] <- k,
         2 <- x do
      assert x == 2
    end
  end

  test "with else" do
    k = [a: 1, b: 2]
    with [a: 1, b: x] <- k,
         3 <- x do
      IO.puts x
    else
      error ->
        assert error == 2
    end

    with [a: 1, b: x] <- k,
         [a: 2, b: 2] <- k do
      IO.puts x
    else
      error ->
        assert error == [a: 1, b: 2]
    end

  end

  test "Enum.group_by" do
    k = [
      [a: 1, b: 1],
      [a: 2, b: 2],
      [a: 1, b: 3],
    ]
    r = k |> Enum.group_by(fn i -> i[:a] end)
    a1 = r[1]
    a2 = r[2]
    assert a1 == [[a: 1, b: 1], [a: 1, b: 3]]
    assert a2 == [[a: 2, b: 2]]
  end


end
