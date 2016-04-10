defmodule McChunk.Bench.SectionBlockAccessAll do
  use Benchfella
  alias McChunk.Section

  defp build_section(palette_len) do
    Section.new_with_palette(for i <- 1..palette_len, do: i)
  end

  bench "Section.get_block (1 bit, all indices)",
    [section: build_section(2)],
    do: for index <- 0..4095, do: Section.get_block(section, index)

  bench "Section.get_block (5 bits, all indices)",
    [section: build_section(32)],
    do: for index <- 0..4095, do: Section.get_block(section, index)

  bench "Section.get_block (7 bits, all indices)",
    [section: build_section(128)],
    do: for index <- 0..4095, do: Section.get_block(section, index)

  bench "Section.set_block (1 bit, all indices)",
    [section: build_section(2)],
    do: for index <- 0..4095, do: Section.set_block(section, index, 1)

  bench "Section.set_block (5 bits, all indices)",
    [section: build_section(32)],
    do: for index <- 0..4095, do: Section.set_block(section, index, 1)

  bench "Section.set_block (7 bits, all indices)",
    [section: build_section(128)],
    do: for index <- 0..4095, do: Section.set_block(section, index, 1)

end
