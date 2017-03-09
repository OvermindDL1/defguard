defmodule DefguardTest do
  use ExUnit.Case
  doctest Defguard

  test "defguard calls" do
    # assert Testering.blah(%{__struct__: Blah}) === 1
    assert Testering.blah(%{__struct__: Blorp}) === 2
    assert Testering.blah(42) === 0
    assert Testering.blorp(%ArithmeticError{}) === "exceptioned"
    assert Testering.blorp(%{__struct__: Blah}) === "No-exception:  %{__struct__: Blah}"
  end
end
