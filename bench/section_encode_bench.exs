defmodule McChunk.Bench.SectionEncode do
  use Benchfella
  alias McChunk.Section

  bench "Section.encode (1 bit)",
    [section: Section.new()],
    do: Section.encode(section)

  bench "Section.encode (8 bits)",
    [section: Section.new_with_palette(for i <- 1..64, do: i)],
    do: Section.encode(section)

end
