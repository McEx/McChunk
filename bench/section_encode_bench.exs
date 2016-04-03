defmodule McChunk.Bench.SectionEncode do
  use Benchfella
  alias McChunk.Section

  bench "Section.encode (1 bit)" do
    Section.encode(%Section{})
  end

  @large_section %Section{block_bits: 8, palette: (for i <- 0..63, do: i),
                          block_array: :array.new(64*8, default: 0)}

  bench "Section.encode (8 bits)" do
    Section.encode(@large_section)
  end

end
