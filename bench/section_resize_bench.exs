defmodule McChunk.Bench.SectionResize do
  use Benchfella
  alias McChunk.Section

  @section_1bit %Section{palette: [0,1]}
  @section_5bit Enum.reduce(0..31, %Section{}, &Section.set_block(&2, &1, &1))
  @section_7bit Enum.reduce(0..127, %Section{}, &Section.set_block(&2, &1, &1))

  bench "resize Section 1->2 bits" do
    Section.set_block(@section_1bit, 999, 999)
  end

  bench "resize Section 5->6 bits" do
    Section.set_block(@section_5bit, 999, 999)
  end

  bench "resize Section 7->8 bits" do
    Section.set_block(@section_7bit, 999, 999)
  end

end
