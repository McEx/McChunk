defmodule McChunk.Bench.ChunkEncode do
  use Benchfella
  alias McChunk.Chunk

  bench "Chunk.encode (1 bit)",
    [section: Chunk.new()],
    do: Chunk.encode(section)

  bench "Chunk.encode (8 bits)",
    [section: Chunk.new_with_palette(for i <- 1..64, do: i)],
    do: Chunk.encode(section)

end
