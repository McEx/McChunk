defmodule McChunk.Bench.SectionBlockAccess do
  use Benchfella
  alias McChunk.Section

  defp build_section(palette_len) do
    Section.new_with_palette(for i <- 1..palette_len, do: i)
  end

  # includes some indices split between longs
  @indices [0, 1, 9, 12, 4083, 4086, 4094, 4095]

  bench "Section.get_block (1 bit)",
    [section: build_section(2)],
    do: for index <- @indices, do: Section.get_block(section, index)

  bench "Section.get_block (5 bits)",
    [section: build_section(32)],
    do: for index <- @indices, do: Section.get_block(section, index)

  bench "Section.get_block (7 bits)",
    [section: build_section(128)],
    do: for index <- @indices, do: Section.get_block(section, index)

  bench "Section.set_block (1 bit)",
    [section: build_section(2)],
    do: for index <- @indices, do: Section.set_block(section, index, 1)

  bench "Section.set_block (5 bits)",
    [section: build_section(32)],
    do: for index <- @indices, do: Section.set_block(section, index, 1)

  bench "Section.set_block (7 bits)",
    [section: build_section(128)],
    do: for index <- @indices, do: Section.set_block(section, index, 1)

end
