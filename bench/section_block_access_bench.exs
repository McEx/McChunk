defmodule McChunk.Bench.SectionBlockAccess do
  use Benchfella
  alias McChunk.Section

  @section_5bit Enum.reduce(0..31, %Section{}, &Section.set_block(&2, &1, &1))
  @section_7bit Enum.reduce(0..127, %Section{}, &Section.set_block(&2, &1, &1))

  bench "Section.get_block:1bit" do
    for index <- 0..4095, do: Section.get_block(%Section{}, index)
  end

  bench "Section.get_block:5bit" do
    for index <- 0..4095, do: Section.get_block(@section_5bit, index)
  end

  bench "Section.get_block:7bit" do
    for index <- 0..4095, do: Section.get_block(@section_7bit, index)
  end

  bench "Section.set_block:1bit" do
    for index <- 0..4095, do: Section.set_block(%Section{}, index, 0)
  end

  bench "Section.set_block:5bit" do
    for index <- 0..4095, do: Section.set_block(@section_5bit, index, 0)
  end

  bench "Section.set_block:7bit" do
    for index <- 0..4095, do: Section.set_block(@section_7bit, index, 0)
  end

end
