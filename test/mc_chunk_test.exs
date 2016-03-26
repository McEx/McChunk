defmodule McChunkTest do
  use ExUnit.Case
  alias McChunk.Chunk
  alias McChunk.Section
  alias McChunk.Palette

  test "chunk decoding" do
    %Chunk{} = Chunk.decode(-1, -1, 0, false, "")
    %Chunk{} = Chunk.decode(-1, -1, 0, true, <<0::2048>>)
    # TODO data, into, partial, no sky light
  end

  test "chunk encoding" do
    {<<0::2048>>, 0} = Chunk.encode(%Chunk{})
    # TODO data, into, partial, no sky light
  end

  test "section decoding" do
    {%Section{}, ""} = Section.decode(-1, <<1, 1, 0, 64, 0::4096*9>>)
    # TODO data, global palette, no sky light
  end

  test "section encoding" do
    <<1, 1, 0, 64, 0::4096*9>> = Section.encode(%Section{})
    # TODO data, global palette, no sky light
  end

  test "palette decoding" do
    {[1, 2, 3], ""} = Palette.decode(<<3, 1, 2, 3>>)

    # length value larger than one byte
    {palette, ""} = Palette.decode(<<0b10101100_00000010::16, 0::300*8>>)
    assert length(palette) == 300
    assert Enum.all? Enum.map palette, &(&1 == 0)

    # large entry
    {[0, 300, 0], ""} = Palette.decode(<<3, 0, 0b10101100_00000010::16, 0>>)
  end

  test "palette encoding" do
    "" = Palette.encode([])
    <<2, 123, 32>> = Palette.encode([123, 32])
    <<0b10101100_00000010::16, 0::300*8>> = Palette.encode(Stream.cycle([0]) |> Enum.take(300))
    <<3, 1, 0b10101100_00000010::16, 0>> = Palette.encode([1, 300, 0])
  end

  test "calculate block bits for palette" do
    1 = Palette.block_bits []
    1 = Palette.block_bits [1]
    1 = Palette.block_bits [1,2]

    2 = Palette.block_bits Enum.to_list 1..3
    2 = Palette.block_bits Enum.to_list 1..4

    3 = Palette.block_bits Enum.to_list 1..5
    3 = Palette.block_bits Enum.to_list 1..8

    4 = Palette.block_bits Enum.to_list 1..9
    4 = Palette.block_bits Enum.to_list 1..16

    5 = Palette.block_bits Enum.to_list 1..17
  end

  test "bulk chunk decode + encode" do
    chunks_dir = "chunks/chunks-1.9.1-pre3-1/"
    chunk_files = File.ls!(chunks_dir)
      |> Enum.filter(&(String.ends_with?(&1, "dump")))
      |> Enum.map(&(chunks_dir <> &1))

    results = for chunk_path <- chunk_files do
      chunk_filename = Regex.run(~r([^/]*$), chunk_path) |> Enum.at(0)
      [_, x, z, _] = String.split(chunk_filename, "_")

      json_str = chunk_path
        |> String.replace("/chunk_", "/packet_")
        |> String.replace(".dump", ".data")
        |> File.read!
      [_, bit_mask_str] = Regex.run(~r/"bitMap":([0-9]*)/, json_str)
      bit_mask_in = String.to_integer(bit_mask_str)

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

end
