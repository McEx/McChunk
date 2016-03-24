defmodule McChunkTest do
  use ExUnit.Case
  doctest Chunk

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "load chunk and check some blocks" do
    bit_mask_in = 0b1111111 # 127
    bin_in = File.read! "chunks/chunks/chunk_-10_5_1457918629636.dump"
    chunk = Chunk.decode(-10, 5, bit_mask_in, true, bin_in)

    filled_sections = for section <- chunk.sections |> Enum.filter(&(&1)) do
      [0 | _] = section.palette
      section.y
    end
    IO.inspect Enum.map filled_sections, &to_string(&1)

    # TODO check some blocks
  end
end
