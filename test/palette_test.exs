Code.require_file "test_helper.exs", __DIR__
import McChunk.Test.Helpers

defmodule McChunk.Test.Palette do
  use ExUnit.Case, async: true
  alias McChunk.Palette

  @varint300 0b1_0101100_0_0000010

  test "palette decoding" do
    assert {[1, 2, 3], ""} == Palette.decode(<<3, 1, 2, 3>>)
    assert {repeat([0], 300), ""} == Palette.decode(<<@varint300::16, 0::300*8>>)
    assert {[0, 300, 0], ""} == Palette.decode(<<3, 0, @varint300::16, 0>>)
  end

  test "palette encoding" do
    assert "" == IO.iodata_to_binary Palette.encode([])
    assert <<2, 123, 32>> == IO.iodata_to_binary Palette.encode([123, 32])
    assert <<@varint300::16, 0::300*8>> == IO.iodata_to_binary Palette.encode(repeat([0], 300))
    assert <<3, 1, @varint300::16, 0>> == IO.iodata_to_binary Palette.encode([1, 300, 0])
  end

  test "calculate block bits for palette" do
    assert 1 == Palette.block_bits []
    assert 1 == Palette.block_bits [1]
    assert 1 == Palette.block_bits [1,2]

    assert 2 == Palette.block_bits Enum.to_list 1..3
    assert 2 == Palette.block_bits Enum.to_list 1..4

    assert 3 == Palette.block_bits Enum.to_list 1..5
    assert 3 == Palette.block_bits Enum.to_list 1..8

    assert 4 == Palette.block_bits Enum.to_list 1..9
    assert 4 == Palette.block_bits Enum.to_list 1..16

    assert 5 == Palette.block_bits Enum.to_list 1..17

    # TODO cap at 13, like vanilla does
  end

end
