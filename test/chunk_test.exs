Code.require_file "test_helper.exs", __DIR__
import McChunk.Test.Helpers

defmodule McChunk.Test.Chunk do
  use ExUnit.Case, async: true
  alias McChunk.Chunk

  test "chunk decoding" do
    assert Chunk.new == Chunk.decode("", Chunk.new, {true, false, 0})
    assert Chunk.new == Chunk.decode(<<0::2048>>, Chunk.new, {true, true, 0})
    # TODO data, into, partial, no sky light
  end

  test "chunk encoding" do
    {iodata, bit_mask} = Chunk.encode(Chunk.new, {true, true, 0})
    assert 0 == bit_mask
    assert <<0::2048>> == IO.iodata_to_binary iodata
    # TODO data, into, partial, no sky light
  end

  test "Chunk.get/set_biome" do
    chunk = Chunk.new
    positions = [{0,0}, {12,3}, {0,15}, {15,0}, {15,15}]
    biomes = [255, 123, 32, 1, 0]
    combined = Enum.zip(positions, biomes)
    chunk = Enum.reduce(combined, chunk, fn {pos, biome}, chunk ->
      Chunk.set_biome(chunk, pos, biome)
    end)
    for {pos, biome} <- combined do
      assert biome == Chunk.get_biome(chunk, pos)
    end
  end

  test "Chunk.(get|set)_(block|sky)_light" do
    c = Chunk.new
    positions = [{0,0,0}, {15,15,15}, {0,16,0}, {15,16,15}, {15,255,15}]
    bls = repeat([15, 0, 12, 3], length positions)
    sls = repeat([12, 0, 3, 15], length positions)
    combined = Enum.zip(positions, Enum.zip(bls, sls))
    c = Enum.reduce(combined, c, fn {pos, {bl, sl}}, c ->
      c = Chunk.set_block_light(c, pos, bl)
      Chunk.set_sky_light(c, pos, sl)
    end)
    for {pos, {bl, sl}} <- combined do
      assert bl == Chunk.get_block_light(c, pos)
      assert sl == Chunk.get_sky_light(c, pos)
    end
  end

  test "Chunk.get/set_block" do
    # TODO
  end

end
