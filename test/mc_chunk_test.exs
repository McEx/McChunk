defmodule McChunkTest do
  use ExUnit.Case
  alias McChunk.Chunk
  alias McChunk.Palette

  test "load chunk and check some blocks" do
    bit_mask_in = 0b1111111 # 127
    bin_in = File.read! "chunks/chunks/chunk_-10_5_1457918629636.dump"
    chunk = Chunk.decode(-10, 5, bit_mask_in, true, bin_in)

    IO.inspect Enum.map chunk.sections, &to_string(&1)

    filled_sections = for section <- chunk.sections |> Enum.filter(&(&1)) do
      [0 | _] = section.palette
      section.y
    end
    IO.inspect Enum.map filled_sections, &to_string(&1)

    # TODO check some blocks

    {bin_out, bit_mask_out} = Chunk.encode(%Chunk{})
    # assert bit_mask_in == bit_mask_out
    # assert bin_in == bin_out
  end

  test "chunk decoding" do
    %Chunk{} = Chunk.decode(-1, -1, 0, false, "")
    %Chunk{} = Chunk.decode(-1, -1, 0, true, <<0::2048>>)
    # TODO
  end

  test "chunk encoding" do
    {<<0::2048>>, 0} = Chunk.encode(%Chunk{})
    # TODO
  end

  test "palette decoding" do
    {[], ""} = Palette.decode(<<0>>)
    {[1, 2, 3], ""} = Palette.decode(<<3, 1, 2, 3>>)

    # length value larger than one byte
    {palette, ""} = Palette.decode(<<0b10101100_00000010::16, 0::300*8>>)
    assert length(palette) == 300
    assert Enum.all? Enum.map palette, &(&1 == 0)

    # large entry
    {[0, 300, 0], ""} = Palette.decode(<<3, 0, 0b10101100_00000010::16, 0>>)
  end

  test "palette encoding" do
    <<0>> = Palette.encode([])
    <<2, 123, 32>> = Palette.encode([123, 32])
    <<0b10101100_00000010::16, 0::300*8>> = Palette.encode(Stream.cycle([0]) |> Enum.take(300))
    <<3, 1, 0b10101100_00000010::16, 0>> = Palette.encode([1, 300, 0])
  end

end
