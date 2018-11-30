defmodule RgenTest do
  use ExUnit.Case
  doctest Rgen

  test "greets the world" do
    assert Rgen.hello() == :world
  end
end
