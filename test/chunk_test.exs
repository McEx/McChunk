Code.require_file "test_helper.exs", __DIR__
import McChunk.Test.Helpers

defmodule McChunk.Test.Chunk do
  use ExUnit.Case, async: true
  alias McChunk.Chunk

  test "chunk decoding" do
    assert %Chunk{} == Chunk.decode("", 0, 0, 0, false)
    assert %Chunk{} == Chunk.decode(<<0::2048>>, 0, 0, 0, true)
    # TODO data, into, partial, no sky light
  end

  test "chunk encoding" do
    {iodata, bit_mask} = Chunk.encode(%Chunk{})
    assert 0 == bit_mask
    assert <<0::2048>> == IO.iodata_to_binary iodata
    # TODO data, into, partial, no sky light
  end

  test "Chunk.pos_to_index" do
    for pos <- [{0, -1, 0}, {0, -999, 0}, {0, 256, 0}, {0, 999, 0}] do
      assert_raise FunctionClauseError, fn ->
        Chunk.pos_to_index(pos)
      end
    end
    for pos <- [{0, 0, 0}, {0, 16, 64}, {-16, 64, -32}] do
      assert 0 == Chunk.pos_to_index(pos)
    end
    for pos <- [{15, 31, 63}, {-1, 255, -65}] do
      assert 4095 == Chunk.pos_to_index(pos)
    end
  end

  test "Chunk.get/set_biome" do
    chunk = %Chunk{}
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
    c = %Chunk{}
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
