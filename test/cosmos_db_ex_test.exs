defmodule CosmosDbExTest do
  use ExUnit.Case
  doctest CosmosDbEx

  test "greets the world" do
    assert CosmosDbEx.hello() == :world
  end
end
