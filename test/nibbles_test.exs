defmodule McChunk.Test.Nibbles do
  use ExUnit.Case, async: true
  alias McChunk.Nibbles

  test "Nibbles" do
    {arr, ""} = Nibbles.decode(<<0x21, 0xfe>>, 4)
    assert [1, 2, 0xe, 0xf] == for i <- 0..3, do: Nibbles.get(arr, i)
    arr = Nibbles.set(arr, 0, 3)
    arr = Nibbles.set(arr, 1, 4)
    arr = Nibbles.set(arr, 2, 5)
    arr = Nibbles.set(arr, 3, 6)
    assert [3, 4, 5, 6] == for i <- 0..3, do: Nibbles.get(arr, i)
    assert <<0x43, 0x65>> == IO.iodata_to_binary(Nibbles.encode(arr))
  end

end
