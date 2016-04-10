defmodule McChunk.Chunk do
  use Bitwise
  alias McChunk.Section
  alias McChunk.Nibbles

  defstruct x: 0, z: 0,
            biome_data: <<0::2048>>,
            sections: for _ <- 0..15, do: nil

  ##### de-/serialization

  def decode(data, x, z, bit_mask, has_biome_data, into \\ %__MODULE__{}) do
    {sections, data} =
      into.sections
      |> Enum.with_index
      |> Enum.reduce({[], data}, fn {old_section, y}, {sections, data} ->
        case ((bit_mask >>> y) &&& 1) do
          0 -> {[old_section | sections], data}
          1 ->
            {section, data} = Section.decode(data, y)
            {[section | sections], data}
        end
      end)
    sections = Enum.reverse sections

    biome_data = if has_biome_data do
      if byte_size(data) != 256, do: raise "wrong biome data size: #{byte_size(data)}"
      data
    else
      into.biome_data
    end

    %__MODULE__{into | x: x, z: z, biome_data: biome_data, sections: sections}
  end

  # sends full chunk and biome data
  # TODO optional bitmask to send only those chunks
  def encode(%__MODULE__{biome_data: biome_data, sections: sections}) do
    {data, bit_mask} =
      sections
      |> Enum.with_index
      |> Enum.reduce({[], 0}, fn {section, y}, {data, bit_mask} ->
        case section do
          nil -> {data, bit_mask}
          section -> {[data, Section.encode(section)], bit_mask ||| (1 <<< y)}
        end
      end)
    {[data, biome_data], bit_mask}
  end

  ##### interaction

  def get_biome(chunk, {x, z}) do
    start = mod(x, 16) + 16 * mod(z, 16)
    <<biome::8>> = binary_part(chunk.biome_data, start, 1)
    biome
  end

  def set_biome(chunk, {x, z}, biome) do
    start = mod(x, 16) + 16 * mod(z, 16)
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
      nil -> 0 # chunk is loaded, section is empty
      section -> func.(section, pos_to_index({x, y, z}))
    end
  end

  defp update_section(chunk, {x, y, z}, func) when y >= 0 and y < 256 do
    %__MODULE__{chunk | sections: List.update_at(chunk.sections, div(y, 16),
      &func.(&1 || %{Section.new() | y: div(y, 16)}, pos_to_index({x, y, z})))}
  end

  ##### helpers

  def pos_to_index({x, y, z}) when y >= 0 and y < 256 do
    mod(x, 16) + 16 * mod(z, 16) + 256 * mod(y, 16)
  end

  defp mod(x, y) when x > 0, do: rem(x, y)
  defp mod(x, y) when x < 0, do: rem(y + rem(x, y), y)
  defp mod(0, _), do: 0

  def idmeta_to_data({id, meta}), do: (id <<< 4) ||| meta
  def data_to_idmeta(data), do: {data >>> 4, data &&& 15}

end
