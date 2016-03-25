defmodule McChunkTest do
  use ExUnit.Case
  doctest Chunk

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
  end

  test "palette decoding" do
    {[], ""} = Palette.decode(<<0>>)
    {[1, 2, 3], ""} = Palette.decode(<<3, 1, 2, 3>>)

    # length value larger than one byte
    {palette, ""} = Palette.decode(<<0b1010110000000010::16, 0::2400>>)
    assert length(palette) == 300
    assert Enum.all? Enum.map palette, &(&1 == 0)
  end

  test "palette encoding" do
    # <<0>> = Palette.encode([])
    # TODO
  end

end
