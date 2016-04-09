defmodule McChunk.Section do
  use Bitwise
  import McChunk.Varint
  alias McChunk.BitArray
  alias McChunk.Palette
  alias McChunk.Nibbles

  # count block usages for empty chunk deletion, reuse unused palette entries?
  defstruct y: -1, palette: [0], block_bits: 1,
            block_array: BitArray.new(64),
            block_light: Nibbles.new(4096),
            sky_light: Nibbles.new(4096)

  def decode(data, y, has_sky \\ true) do
    <<block_bits::8, data::binary>> = data

    {palette, data} = case block_bits do
      0 -> {[], data}
      _ -> Palette.decode(data)
    end

    {num_longs, data} = decode_varint(data)
    {block_array, data} = BitArray.decode(data, num_longs)

    {block_light, data} = Nibbles.decode(data, 4096)

    {sky_light, data} = if has_sky do
      Nibbles.decode(data, 4096)
    else
      {nil, data}
    end

    {%__MODULE__{y: y, palette: palette,
      block_bits: block_bits, block_array: block_array,
      block_light: block_light, sky_light: sky_light}, data}
  end

  def encode(section, has_sky \\ true) do
    block_longs = BitArray.encode(section.block_array)
    sky_light = if has_sky, do: Nibbles.encode(section.sky_light), else: []
    [
      section.block_bits,
      Palette.encode(section.palette),
      encode_varint(length block_longs),
      block_longs,
      Nibbles.encode(section.block_light)
      | sky_light
    ]
  end

  def get_block(section, index) do
    %__MODULE__{palette: palette, block_bits: bbits, block_array: arr} = section
    {uses_palette, bbits} = case bbits do
      0 -> {false, 13}
      bb -> {true, bb}
    end

    block_key = BitArray.get(arr, bbits, index)
    if uses_palette do
      Enum.at(palette, block_key)
    else
      block_key # already global palette
    end
  end

  def set_block(section, index, block) do
    {palette, bbits, arr, block_key} = lookup_or_grow(section, block)
    arr = BitArray.set(arr, bbits, index, block_key)
    # TODO shrink the palette if we overwrote the last usage of a block

    %__MODULE__{section | palette: palette, block_bits: bbits, block_array: arr}
  end

  defp lookup_or_grow(%__MODULE__{palette: [], block_bits: 0, block_array: arr}, block),
    do: {[], 0, arr, block} # global palette
  defp lookup_or_grow(section, block) do
    %__MODULE__{palette: palette, block_bits: bbits, block_array: arr} = section
    case Palette.lookup(palette, block) do
      nil ->
        block_key = length palette
        new_palette = palette ++ [block]
        required_bbits = Palette.block_bits(new_palette)

        if bbits >= required_bbits do
          {new_palette, bbits, arr, block_key}

        else # palette requires more bits, grow block_array
          new_num_longs = trunc Float.ceil(4096 * required_bbits / 8 / 8)
          new_arr = BitArray.new(new_num_longs)
          new_arr = Enum.reduce(0..4095, new_arr, fn index, new_arr ->
            value = BitArray.get(arr, bbits, index)
            BitArray.set(new_arr, required_bbits, index, value)
          end)

          {new_palette, required_bbits, new_arr, block_key}
        end

      block_key -> {palette, bbits, arr, block_key}
    end
  end

end

defimpl String.Chars, for: McChunk.Section do
  def to_string(nil), do: "#Section<empty>"
  def to_string(%McChunk.Section{y: y, block_bits: block_bits, palette: palette}),
    do: "#Section<y=#{y}, #{block_bits} bits, palette=#{inspect palette}>"
end
