Code.require_file "test_helper.exs", __DIR__
import McChunk.Test.Helpers

defmodule McChunk.Test.RealChunks do
  use ExUnit.Case, async: true
  alias McChunk.Chunk

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

end
