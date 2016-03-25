defmodule McChunk.Chunk do
  use Bitwise
  alias McChunk.Chunk
  alias McChunk.Section

  defstruct x: 0, z: 0, biome_data: <<0::2048>>, sections: for _ <- 0..15, do: nil

  def decode(x, z, bit_mask, has_biome_data, data, into \\ %Chunk{}) do
    {sections, data, 16} = Enum.reduce into.sections, {[], data, 0},
      fn old_section, {sections, data, y} ->
        {section, data} = if ((bit_mask >>> y) &&& 1) != 0 do
          Section.decode(y, data)
        else
          {old_section, data}
        end
        {[section | sections], data, y+1}
      end
    sections = Enum.reverse sections

    biome_data = if has_biome_data do
      <<_::2048>> = data
    else
      into.biome_data
    end

    %Chunk{into | x: x, z: z, biome_data: biome_data, sections: sections}
  end

  # sends full chunk and biome data
  # TODO optional bitmask to send only those chunks
  def encode(%Chunk{biome_data: biome_data, sections: sections}) do
    {data, bit_mask, 16} = Enum.reduce sections, {"", 0, 0},
      fn section, {data, bit_mask, y} ->
        case section do
          nil -> {data, bit_mask, y+1}
          section -> {data <> Section.encode(section), bit_mask ||| (1 <<< y), y+1}
        end
      end
    {data <> biome_data, bit_mask}
  end

end
