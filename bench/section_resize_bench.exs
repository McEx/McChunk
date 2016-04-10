defmodule McChunk.Bench.SectionResize do
  use Benchfella
  alias McChunk.Section

  defp build_section(palette_len) do
    Section.new_with_palette(for i <- 1..palette_len, do: i)
  end

  bench "resize Section 1->2 bits",
    [section: build_section(2)],
    do: Section.set_block(section, 999, 999)

  bench "resize Section 5->6 bits",
    [section: build_section(32)],
    do: Section.set_block(section, 999, 999)

  bench "resize Section 7->8 bits",
    [section: build_section(128)],
    do: Section.set_block(section, 999, 999)

end
