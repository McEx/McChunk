defmodule McChunkTest do
  use ExUnit.Case, async: true
  alias McChunk.Chunk
  alias McChunk.Section
  alias McChunk.Palette
  alias McChunk.Nibbles

  @block_store Application.get_env(:mc_chunk, :block_store)

  @varint300 0b1_0101100_0_0000010

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

  @small_section_binary <<1, 1, 0, 64, 0::4096*9>>
  @large_section_binary <<8, 64, 0::512, 128, 4, 0::4096*8, 0::4096*8>>

  test "section decoding" do
    {s, rest} = Section.decode(@small_section_binary, -1)
    assert rest == ""
    assert s.palette == [0]
    assert s.block_bits == 1
    assert s.y == -1

    # unfilled, default-0 array looks different than filled, compare entries
    for i <- 0..4095, do: assert 0 == apply(@block_store, :get, [s.block_array, 1, i])
    for i <- 0..2047, do: assert 0 == :array.get(i, s.block_light)
    for i <- 0..2047, do: assert 0 == :array.get(i, s.sky_light)

    {s, rest} = Section.decode(@large_section_binary, -1)
    assert rest == ""
    assert s.palette == for _ <- 0..63, do: 0
    assert s.block_bits == 8
    assert s.y == -1

    for i <- 0..4095, do: assert 0 == apply(@block_store, :get, [s.block_array, 8, i])
    for i <- 0..2047, do: assert 0 == :array.get(i, s.block_light)
    for i <- 0..2047, do: assert 0 == :array.get(i, s.sky_light)

    # TODO data, global palette, no sky light
  end

  test "section encoding" do
    encoded_small_section_binary = IO.iodata_to_binary Section.encode(Section.new())
    assert @small_section_binary == encoded_small_section_binary

    large_section = %{Section.new() | block_bits: 8, palette: (for _ <- 0..63, do: 0),
                      block_array: apply(@block_store, :new, [64*8])}
    encoded_large_section_binary = IO.iodata_to_binary Section.encode(large_section)
    assert @large_section_binary == encoded_large_section_binary
    # TODO data, global palette, no sky light
  end

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

  test "Chunk.get/set_block" do
    # TODO
  end

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

  test "Section.get/set_block" do
    # single bit, two palette entries, non-zero first entry
    s = %{Section.new() | palette: [42, 123]}
    s = Enum.reduce([{0, 0, 0}, {15, 255, -9999}], s, fn pos, s ->
      index = Chunk.pos_to_index(pos)
      assert 42 == Section.get_block(s, index)
      s = Section.set_block(s, index, 123)
      assert 123 == Section.get_block(s, index)
      assert 1 == s.block_bits
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
      assert s.block_bits > 1
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

  test "load chunk -10,5 and check some blocks" do
    path = "test_chunks/chunk_-10_5_1457918629636.dump"
    chunk = Chunk.decode(File.read!(path), -10, 5, 0b1111111, true)

    assert 7 == length Enum.filter chunk.sections, &(&1)

    assert chunk.biome_data == [6] |> repeat(256) |> List.to_string

    assert Enum.at(chunk.sections, 6).palette == [0, 16, 32, 64, 256, 1523, 1524, 1525, 1526]

    some_blocks = for z <- 0..5, do: for x <- 0..15, do: Chunk.get_block(chunk, {x, 6*16, z})
    assert some_blocks == [repeat([16, 32, 64, 256], 16), repeat([16], 16), repeat([32], 16), repeat([64], 16), repeat([256], 16), repeat([0], 16)]

    some_blocks = for y <- 0..5, do: Chunk.get_block(chunk, {0, 6*16+y, 0})
    assert some_blocks == [16, 1523, 1524, 1525, 1526, 0]
  end

  test "bulk chunk decode + encode" do
    chunks_dir = "test_chunks/"
    chunk_files =
      chunks_dir
      |> File.ls!
      |> Enum.filter(&(String.ends_with?(&1, "dump")))
      |> Enum.map(&(chunks_dir <> &1))

    results = for chunk_path <- chunk_files do
      [chunk_filename] = Regex.run(~r([^/]*$), chunk_path)
      [_, x, z, _] = String.split(chunk_filename, "_")
      bit_mask_in = bit_mask_from_chunk_path(chunk_path)

      bin_in = File.read!(chunk_path)
      chunk = Chunk.decode(bin_in, x, z, bit_mask_in, true)
      {bin_out, bit_mask_out} = Chunk.encode(chunk)

      if bit_mask_in != bit_mask_out or bin_in != IO.iodata_to_binary(bin_out) do
        n_diff_sections = chunk.sections |> Enum.filter(&(&1)) |> length
        IO.puts "different: #{chunk_filename} sections: #{n_diff_sections}"
        for section <- chunk.sections |> Enum.filter(&(&1)),
          do: IO.puts "  #{section}"
        chunk_filename
      end
    end
    failed_chunks = Enum.filter(results, &(&1))
    IO.puts "re-encoded #{length chunk_files} chunks, #{length failed_chunks} failures"
    assert length(failed_chunks) == 0
  end

  defp bit_mask_from_chunk_path(chunk_path) do
      json_str =
        chunk_path
        |> String.replace("/chunk_", "/packet_")
        |> String.replace(".dump", ".data")
        |> File.read!
      [_, bit_mask_str] = Regex.run(~r/"bitMap":([0-9]*)/, json_str)
      String.to_integer(bit_mask_str)
  end

  defp repeat(vals, len), do: vals |> Stream.cycle |> Enum.take(len)

end
