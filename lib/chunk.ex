defmodule McChunk.Chunk do
  use Bitwise
  import McChunk.Utils
  alias McChunk.Section
  alias McChunk.Nibbles

  defstruct has_sky: true,
            biome_data: <<0::2048>>,
            sections: for _ <- 0..15, do: nil

  def new(), do: %__MODULE__{}

  ##### de-/serialization

  def decode(data, into, {has_sky, has_biome, bit_mask}) do
    {sections, data} =
      into.sections
      |> Enum.with_index
      |> Enum.reduce({[], data}, fn {old_section, y}, {sections, data} ->
        if ((bit_mask >>> y) &&& 1) == 1 do
          {section, data} = Section.decode(data, y, has_sky)
          {[section | sections], data}
        else
          {[old_section | sections], data}
        end
      end)
    sections = Enum.reverse sections

    biome_data = if has_biome do
      if byte_size(data) != 256, do: raise "wrong biome data size: #{byte_size(data)}"
      data
    else
      into.biome_data
    end

    %__MODULE__{into |
      has_sky: has_sky,
      biome_data: biome_data,
      sections: sections,
    }
  end

  def encode(chunk, {has_sky, has_biome, only_bit_mask}) do
    only_bit_mask = if only_bit_mask == 0,
      do: 0xffff,
      else: only_bit_mask
    {data, bit_mask} =
      chunk.sections
      |> Enum.with_index
      |> Enum.filter(fn {section, y} -> ((only_bit_mask >>> y) &&& 1) == 1 end)
      |> Enum.reduce({[], 0}, fn {section, y}, {data, bit_mask} ->
        case section do
          nil -> {data, bit_mask}
          section -> {[data, Section.encode(section, has_sky)], bit_mask ||| (1 <<< y)}
        end
      end)
    data = if has_biome,
      do: [data, chunk.biome_data],
      else: data
    {data, bit_mask}
  end

  ##### interaction

  def get_biome(chunk, pos) do
    start = pos2_to_index(pos)
    <<biome::8>> = binary_part(chunk.biome_data, start, 1)
    biome
  end

  def set_biome(chunk, pos, biome) do
    start = pos2_to_index(pos)
    <<before::binary-size(start), _::8, rest::binary>> = chunk.biome_data
    biome_data = <<before::binary, biome::8, rest::binary>>
    %__MODULE__{chunk | biome_data: biome_data}
  end

  def get_block(chunk, pos) do
    access_section(chunk, pos, &Section.get_block/2)
  end

  def set_block(chunk, pos, block) do
    update_section(chunk, pos, &Section.set_block(&1, &2, block))
  end

  def get_block_light(chunk, pos) do
    access_section(chunk, pos, &Nibbles.get(&1.block_light, &2))
  end

  def set_block_light(chunk, pos, light) do
    update_section(chunk, pos, fn section, index ->
      %Section{section | block_light: Nibbles.set(section.block_light, index, light)}
    end)
  end

  def get_sky_light(chunk, pos) do
    access_section(chunk, pos, &Nibbles.get(&1.sky_light, &2))
  end

  def set_sky_light(chunk, pos, light) do
    update_section(chunk, pos, fn section, index ->
      %Section{section | sky_light: Nibbles.set(section.sky_light, index, light)}
    end)
  end

  defp access_section(_, {_, y, _}, _) when y < 0 or y >= 256, do: 0
  defp access_section(chunk, {x, y, z}, func) do
    case Enum.at(chunk.sections, div(y, 16)) do
      nil -> 0 # chunk is loaded, section is air
      section -> func.(section, pos3_to_index({x, y, z}))
    end
  end

  defp update_section(chunk, {x, y, z}, func) when y >= 0 and y < 256 do
    %__MODULE__{chunk | sections: List.update_at(chunk.sections, div(y, 16),
      &func.(&1 || Section.new(y: div(y, 16)), pos3_to_index({x, y, z})))}
  end

  defp update_section(chunk, index, func) when index >= 0 and index < 65536 do
    %__MODULE__{chunk | sections: List.update_at(chunk.sections, div(index, 4096),
      &func.(&1 || Section.new(y: div(index, 4096)), rem(index, 4096)))}
  end

end
