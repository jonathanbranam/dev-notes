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

  test "float notation" do
    # WRONG 1e2
    # WRONG 1.e2
    # RIGHT:
    assert 1.0e2 == 100
    assert 0.1e2 == 10
  end

  test "asserting with a delta" do
    assert_in_delta 0.1 + 0.1, 0.200001, 0.0001
  end

  test "date literal sigil" do
    assert ~D[2019-03-04] == ~D[2019-03-04]
    assert ~D[2019-12-21] == %Date{year: 2019, month: 12, day: 21}
  end

  test "datetime literal sigil" do
    # ~N creates a NaiveDateTime with no timezone attached
    assert ~N[2019-03-04 03:12:00] == ~N[2019-03-04 03:12:00]
    assert ~N[2019-03-04 03:12:00] == %NaiveDateTime{year: 2019, month: 3, day: 4,
      hour: 3, minute: 12, second: 0}
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

  test "Enum.map" do
    k = [1, 2, 3, 4]
    r = k |> Enum.map(fn i -> i * 2 end)
    assert r == [2, 4, 6, 8]
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

  test "Enum.each on struct" do
    k = [
      [a: 1, b: 1],
      [a: 2, b: 2],
      [a: 1, b: 3],
    ]
    r = k |> Enum.group_by(fn i -> i[:a] end)
    # Enum.each throws out the return value so... not sure how to test better
    assert :ok == r |> Enum.each(fn {_v, as} -> length(as) end)
  end

  test "simple list concat" do
    a = [1, 2, 3]
    b = [4, 5, 6]
    assert a ++ b == [1, 2, 3, 4, 5, 6]
  end

  test "list concat dups" do
    a = [1, 2, 3]
    b = [3, 2, 6]
    assert a ++ b == [1, 2, 3, 3, 2, 6]
  end

  test "default arguments" do
    # def defarg(x, e \\ 2) do
    #   :math.pow(x, e)
    # end
    assert Learn.defarg(3) == 9
    assert Learn.defarg(3, 2) == 9
    assert Learn.defarg(3, 3) == 27
  end

  test "Enum.reduce add" do
    a = [1, 2, 3, 4]
    b = a |> Enum.reduce(0, fn i, r -> i + r end)
    assert b == 10
  end

  test "Enum.reduce build list" do
    a = [1, 2, 3, 4]
    b = a |> Enum.reduce([], fn i, r -> r ++ [-i] end)
    assert b == [-1, -2, -3, -4]
  end

  test "Enum.reduce nested" do
    a = [1, 2]
    b = Enum.reduce(a, [], fn i, r ->
      r ++
        Enum.reduce(a, r, fn j, r ->
          [{i, j} | r]
        end)
    end)
    assert b == [{1, 2}, {1, 1}, {2, 2}, {2, 1}, {1, 2}, {1, 1}]
  end

  test "Enum.reduce nested with filter" do
    # you can't def inside a test
    nested_reduce = fn a ->
      Enum.reduce(Enum.filter(a, &(&1 == 1)), [], fn i, r ->
        r ++
          Enum.reduce(Enum.filter(a, &(&1 != 1)), r, fn j, r ->
            [{i, j} | r]
          end)
      end)
    end
    # Because the first reduce only matches a single element in a, the body of
    # the reduce will only be executed once which avoids the possible
    # compounding problem
    b = nested_reduce.([1, 2, 3, 4])
    assert b == [{1, 4}, {1, 3}, {1, 2}]

    # If we pass an array with two matching elements then we get a duplicate of
    # the first result of the inner reduce and end up with 3 copies instead of
    # 2.
    b = nested_reduce.([1, 1, 2, 3, 4])
    # This is not what we wanted: we get an extra copy because r is passed as
    # the accumulator to the nested reduce()
    assert b == [
      {1, 4}, {1, 3}, {1, 2},
      {1, 4}, {1, 3}, {1, 2},
      {1, 4}, {1, 3}, {1, 2},
    ]
  end

  test "Enum.reduce nested with filter fixing double concat" do
    nested_reduce = fn a ->
      Enum.reduce(Enum.filter(a, &(&1 == 1)), [], fn i, r ->
        Enum.reduce(Enum.filter(a, &(&1 != 1)), r, fn j, r ->
          [{i, j} | r]
        end)
      end)
    end
    b = nested_reduce.([1, 2, 3, 4])
    assert b == [{1, 4}, {1, 3}, {1, 2}]

    b = nested_reduce.([1, 1, 2, 3, 4])
    assert b == [
      {1, 4}, {1, 3}, {1, 2},
      {1, 4}, {1, 3}, {1, 2},
    ]
  end

  test "Enum.reduce nested with filter fixing double concat 2" do
    nested_reduce = fn a ->
      Enum.reduce(Enum.filter(a, &(&1 == 1)), [], fn i, r ->
        r ++
          Enum.reduce(Enum.filter(a, &(&1 != 1)), [], fn j, r ->
            [{i, j} | r]
          end)
      end)
    end
    b = nested_reduce.([1, 2, 3, 4])
    assert b == [{1, 4}, {1, 3}, {1, 2}]

    b = nested_reduce.([1, 1, 2, 3, 4])
    assert b == [
      {1, 4}, {1, 3}, {1, 2},
      {1, 4}, {1, 3}, {1, 2},
    ]
  end

end
