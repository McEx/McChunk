Code.require_file "test_helper.exs", __DIR__
import McChunk.Test.Helpers
import McChunk.Utils

defmodule McChunk.Test.Section do
  use ExUnit.Case, async: true
  alias McChunk.Section
  alias McChunk.BlockStore
  alias McChunk.Nibbles

  @fullbright IO.iodata_to_binary for _ <- 1..4096, do: 0xff
  @small_section_binary <<4, 1, 0, 128, 2, 0::4096*4, @fullbright::binary>>
  @large_section_binary <<8, 64, 0::512, 128, 4, 0::4096*8, @fullbright::binary>>

  test "section decoding" do
    {s, rest} = Section.decode(@small_section_binary, -1)
    assert rest == ""
    assert s.palette == [0]
    assert s.block_bits == 4
    assert s.y == -1

    # unfilled, default-0 array looks different than filled, compare entries
    for i <- 0..4095, do: assert 0 == BlockStore.get(s.block_array, s.block_bits, i)
    for i <- 0..4095, do: assert 15 == Nibbles.get(s.block_light, i)
    for i <- 0..4095, do: assert 15 == Nibbles.get(s.sky_light, i)

    {s, rest} = Section.decode(@large_section_binary, -1)
    assert rest == ""
    assert s.palette == for _ <- 0..63, do: 0
    assert s.block_bits == 8
    assert s.y == -1

    for i <- 0..4095, do: assert 0 == BlockStore.get(s.block_array, s.block_bits, i)
    for i <- 0..4095, do: assert 15 == Nibbles.get(s.block_light, i)
    for i <- 0..4095, do: assert 15 == Nibbles.get(s.sky_light, i)

    # TODO data, global palette, no sky light
  end

  test "section encoding" do
    encoded_small_section_binary = IO.iodata_to_binary Section.encode(Section.new())
    assert @small_section_binary == encoded_small_section_binary

    large_section = Section.new(
      block_bits: 8,
      palette: (for _ <- 0..63, do: 0),
      block_array: BlockStore.new(64*8))
    encoded_large_section_binary = IO.iodata_to_binary Section.encode(large_section)
    assert @large_section_binary == encoded_large_section_binary
    # TODO data, global palette, no sky light
  end

  test "Section.get/set_block" do
    # single bit, two palette entries, non-zero first entry
    s = Section.new(palette: [42, 123])
    s = Enum.reduce([{0, 0, 0}, {15, 255, -9999}], s, fn pos, s ->
      index = pos3_to_index(pos)
      assert 42 == Section.get_block(s, index)
      s = Section.set_block(s, index, 123)
      assert 123 == Section.get_block(s, index)
      assert 4 == s.block_bits
      assert s.palette == [42, 123]
      s
    end)

    # grow palette to 16 blocks
    new_blocks = for b <- 1..14, do: 2*b
    new_palette = s.palette ++ new_blocks
    indices = Enum.to_list(0..32) ++ Enum.to_list(4090..4095)

    indices_x_blocks = for index <- indices, block <- new_blocks, do: {index, block}
    s = Enum.reduce(indices_x_blocks, s, fn {index, block}, s ->
      s = Section.set_block(s, index, block)
      assert 4 == s.block_bits
      assert block == Section.get_block(s, index)
      s
    end)
    assert 4 == s.block_bits
    assert s.palette == new_palette

    # persistence
    blocks = repeat(s.palette, length indices)
    s = Enum.reduce(Enum.zip(indices, blocks), s, fn {index, block}, s ->
      Section.set_block(s, index, block)
    end)
    assert 4 == s.block_bits
    assert s.palette == new_palette
    for {index, block} <- Enum.zip(indices, blocks) do
      assert block == Section.get_block(s, index)
    end
    assert 4 == s.block_bits
    assert s.palette == new_palette

    # one more block to require 5 bits
    s = Section.set_block(s, 33, 43)
    assert 5 == s.block_bits
    assert 43 == Section.get_block(s, 33)
    # resizing did not change previous blocks
    for {index, block} <- Enum.zip(indices, blocks) do
      assert block == Section.get_block(s, index)
    end

    # TODO check that block_data changed
    # TODO global palette
  end

end
