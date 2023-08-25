defmodule MiddleAiTest do
  use ExUnit.Case
  doctest MiddleAi

  test "greets the world" do
    assert MiddleAi.hello() == :world
  end
end
