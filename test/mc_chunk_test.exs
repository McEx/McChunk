defmodule McChunkTest do
  use ExUnit.Case
  alias McChunk.Chunk
  alias McChunk.Section
  alias McChunk.Palette

  @varint300 0b10101100_00000010

  test "chunk decoding" do
    %Chunk{} = Chunk.decode(-1, -1, 0, false, "")
    %Chunk{} = Chunk.decode(-1, -1, 0, true, <<0::2048>>)
    # TODO data, into, partial, no sky light
  end

  test "chunk encoding" do
    assert {<<0::2048>>, 0} == Chunk.encode(%Chunk{})
    # TODO data, into, partial, no sky light
  end

  test "section decoding" do
    {%Section{}, ""} = Section.decode(-1, <<1, 1, 0, 64, 0::4096*9>>)
    # TODO data, global palette, no sky light
  end

  test "section encoding" do
    assert <<1, 1, 0, 64, 0::4096*9>> == Section.encode(%Section{})
    # TODO data, global palette, no sky light
  end

  test "palette decoding" do
    assert {[1, 2, 3], ""} == Palette.decode(<<3, 1, 2, 3>>)
    assert {repeat([0], 300), ""} == Palette.decode(<<@varint300::16, 0::300*8>>)
    assert {[0, 300, 0], ""} == Palette.decode(<<3, 0, @varint300::16, 0>>)
  end

  test "palette encoding" do
    assert "" == Palette.encode([])
    assert <<2, 123, 32>> == Palette.encode([123, 32])
    assert <<@varint300::16, 0::300*8>> == Palette.encode(repeat([0], 300))
    assert <<3, 1, @varint300::16, 0>> == Palette.encode([1, 300, 0])
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

  test "Chunk.get/set_block" do
    # TODO
  end

  test "Section.get/set_block" do
    s = %Section{palette: [42, 123]}
    # different kinds of coordinates
    for pos <- [{0, 0, 0}, {15, 255, -9999}] do
      index = Chunk.pos_to_index(pos)
      assert 42 == Section.get_block(s, index)
      s = Section.set_block(s, index, 123)
      assert 123 == Section.get_block(s, index)
      s = Section.set_block(s, index, 42)
      assert 42 == Section.get_block(s, index)
    end
    assert s.palette == [42, 123]

    # TODO grow palette and block_array

    # TODO update block_data
  end

  test "load chunk -10,5 and check some blocks" do
    path = "chunks/chunks/chunk_-10_5_1457918629636.dump"
    chunk = Chunk.decode(-10, 5, 0b1111111, true, File.read! path)

    assert 7 == length Enum.filter chunk.sections, &(&1)

    # IO.inspect to_char_list(chunk.biome_data) |> Enum.filter(&(&1 != 6))

    assert chunk.biome_data == repeat([6], 256) |> List.to_string

    assert Enum.at(chunk.sections, 6).palette == [0, 16, 32, 64, 256, 1523, 1524, 1525, 1526]

    some_blocks = for z <- 0..5, do: for x <- 0..15, do: Chunk.get_block(chunk, {x, 6*16, z})
    assert some_blocks == [repeat([16, 32, 64, 256], 16), repeat([16], 16), repeat([32], 16), repeat([64], 16), repeat([256], 16), repeat([0], 16)]
  end

  test "bulk chunk decode + encode" do
    chunks_dir = "chunks/chunks-1.9.1-pre3-1/"
    chunk_files = File.ls!(chunks_dir)
      |> Enum.filter(&(String.ends_with?(&1, "dump")))
      |> Enum.map(&(chunks_dir <> &1))

    results = for chunk_path <- chunk_files do
      [chunk_filename] = Regex.run(~r([^/]*$), chunk_path)
      [_, x, z, _] = String.split(chunk_filename, "_")
      bit_mask_in = bit_mask_from_chunk_path(chunk_path)

      bin_in = File.read!(chunk_path)
      chunk = Chunk.decode(x, z, bit_mask_in, true, bin_in)
      {bin_out, bit_mask_out} = Chunk.encode(chunk)

      if bit_mask_in != bit_mask_out or bin_in != bin_out do
        IO.puts "different: #{chunk_filename} sections: #{length(Enum.filter chunk.sections, &(&1))}"
        for section <- chunk.sections |> Enum.filter(&(&1)), do: IO.puts "  #{section}"
        chunk_filename
      end
    end
    failed_chunks = Enum.filter(results, &(&1))
    IO.puts "re-encoded #{length chunk_files} chunks, #{length failed_chunks} failures"
    assert length(failed_chunks) == 0
  end

  defp bit_mask_from_chunk_path(chunk_path) do
      json_str = chunk_path
        |> String.replace("/chunk_", "/packet_")
        |> String.replace(".dump", ".data")
        |> File.read!
      [_, bit_mask_str] = Regex.run(~r/"bitMap":([0-9]*)/, json_str)
      String.to_integer(bit_mask_str)
  end

  defp repeat(vals, len), do: Stream.cycle(vals) |> Enum.take(len)

end
