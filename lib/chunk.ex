defmodule McChunk.Chunk do
  use Bitwise
  alias McChunk.Section

  defstruct x: 0, z: 0, biome_data: <<0::2048>>, sections: for _ <- 0..15, do: nil

  def decode(x, z, bit_mask, has_biome_data, data, into \\ %__MODULE__{}) do
    {sections, data} = Enum.reduce Enum.with_index(into.sections), {[], data},
      fn {old_section, y}, {sections, data} ->
        {section, data} = case ((bit_mask >>> y) &&& 1) do
          1 -> Section.decode(y, data)
          0 -> {old_section, data}
        end
        {[section | sections], data}
      end
    sections = Enum.reverse sections

    <<biome_data::bitstring-size(2048)>> = if has_biome_data do
      <<_::2048>> = data
    else
      into.biome_data
    end

    %__MODULE__{into | x: x, z: z, biome_data: biome_data, sections: sections}
  end

  # sends full chunk and biome data
  # TODO optional bitmask to send only those chunks
  def encode(%__MODULE__{biome_data: biome_data, sections: sections}) do
    {data, bit_mask} = Enum.reduce Enum.with_index(sections), {"", 0},
      fn {section, y}, {data, bit_mask} ->
        case section do
          nil -> {data, bit_mask}
          section -> {data <> Section.encode(section), bit_mask ||| (1 <<< y)}
        end
      end
    {data <> biome_data, bit_mask}
  end

end
