defmodule McChunk.Bench.SectionDecode do
  use Benchfella
  alias McChunk.Section

  bench "Section.decode (1 bit)" do
    Section.decode(<<1, 1, 0, 64, 0::4096*9>>, -1)
  end

  bench "Section.decode (8 bits)" do
    Section.decode(<<8, 64, 0::512, 128, 4, 0::4096*8, 0::4096*8>>, -1)
  end

end
