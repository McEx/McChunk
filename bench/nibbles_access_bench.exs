defmodule McChunk.Bench.NibblesAccess do
  use Benchfella
  alias McChunk.Nibbles

  @arr Nibbles.new(4096)

  bench "Nibbles.get" do
    for index <- 0..4095, do: Nibbles.get(@arr, index)
  end

  bench "Nibbles.set" do
    for index <- 0..4095, do: Nibbles.set(@arr, index, 15)
  end

end
