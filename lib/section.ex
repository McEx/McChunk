defmodule McChunk.Section do
  use Bitwise
  import McChunk.Varint
  alias McChunk.Palette

  # count block usages for empty chunk deletion, reuse unused palette entries?
  defstruct y: -1, palette: [0], block_bits: 1,
            block_array: :array.new(64, default: 0),
            block_light: <<0::4096*4>>,
            sky_light: <<0::4096*4>>

  def decode(y, data) do
    <<block_bits, data::binary>> = data
    {palette, data} = case block_bits do
      0 -> {[], data}
      _ -> Palette.decode(data)
    end

    {num_longs, data} = decode_varint(data)
    {block_array, data} = decode_block_data(num_longs, data)
    <<block_light::binary-size(2048), data::binary>> = data

    # TODO no sky light in the nether
    <<sky_light::binary-size(2048), data::binary>> = data

    {%__MODULE__{y: y, palette: palette,
      block_bits: block_bits, block_array: block_array,
      block_light: block_light, sky_light: sky_light}, data}
  end

  defp decode_block_data(num_longs, data) do
    Enum.reduce 0..num_longs-1, {:array.new(num_longs), data},
    fn i, {block_array, data} ->
      <<long_val::big-integer-size(64), data::binary>> = data
      {:array.set(i, long_val, block_array), data}
    end
  end

  def encode(%__MODULE__{palette: palette, block_bits: block_bits,
    block_array: block_array, block_light: block_light, sky_light: sky_light}) do
    block_data = for long_val <- :array.to_list(block_array),
      into: "", do: <<long_val::big-integer-size(64)>>
    <<block_bits>>
    <> Palette.encode(palette)
    <> encode_varint(div(byte_size(block_data), 8))
    <> block_data
    <> block_light
    <> sky_light
  end

  def get_block(%__MODULE__{palette: palette, block_bits: bbits,
    block_array: arr}, index) do
    {uses_palette, bbits} = case bbits do
      0 -> {false, 13}
      bb -> {true, bb}
    end

    block = bitarray_get(arr, bbits, index)

    if uses_palette do
      Enum.at(palette, block)
    else
      block # already global palette
    end
  end

  def set_block(section, index, block) do
    {palette, bbits, arr, block_key} = lookup_or_grow(section, block)
    arr = bitarray_set(arr, bbits, index, block_key)
    # TODO shrink the palette if we overwrote the last usage of a block

    %__MODULE__{section | palette: palette, block_bits: bbits, block_array: arr}
  end

  defp bitarray_get(arr, bbits, index) do
    max_value = (1 <<< bbits) - 1
    start_long = div(index * bbits, 64)
    start_offset = rem(index * bbits, 64)
    end_long = div((index + 1) * bbits - 1, 64)

    start_val = :array.get(start_long, arr) >>> start_offset

    if start_long == end_long do
      start_val
    else
      end_offset = 64 - start_offset
      end_val = :array.get(end_long, arr) <<< end_offset

      (start_val ||| end_val)
    end &&& max_value
  end

  defp bitarray_set(arr, bbits, index, value) do
    max_value = (1 <<< bbits) - 1
    start_long = div(index * bbits, 64)
    start_offset = rem(index * bbits, 64)
    end_long = div((index + 1) * bbits - 1, 64)

    start_val_a = :array.get(start_long, arr) &&& bnot(max_value <<< start_offset)
    start_val_b = (value &&& max_value) <<< start_offset
    arr = :array.set(start_long, start_val_a ||| start_val_b, arr)

    if start_long != end_long do
      end_offset = 64 - start_offset
      j1 = bbits - end_offset
      end_val_a = :array.get(end_long, arr) >>> j1 <<< j1
      end_val_b = (value &&& max_value) >>> end_offset

      :array.set(end_long, end_val_a ||| end_val_b, arr)
    else
      arr
    end
  end

  defp lookup_or_grow(%__MODULE__{palette: [],
    block_bits: 0, block_array: arr}, block) do
    {[], 0, arr, block} # global palette
  end
  defp lookup_or_grow(%__MODULE__{palette: palette,
    block_bits: bbits, block_array: arr}, block) do
    case Palette.lookup(palette, block) do
      nil ->
        block_key = length palette
        new_palette = palette ++ [block]
        required_bbits = Palette.block_bits(new_palette)

        if bbits >= required_bbits do
          {new_palette, bbits, arr, block_key}
        else # palette requires more bits, grow block_array
          new_num_longs = trunc Float.ceil(4096 * required_bbits / 8 / 8)
          # TODO custom bit shifting magic to add a 0 to every bitarray entry
          new_arr = Enum.reduce 0..4095, :array.new(new_num_longs, default: 0),
            fn index, arr ->
              value = bitarray_get(arr, bbits, index)
              bitarray_set(arr, bbits, index, value)
            end

          {new_palette, required_bbits, new_arr, block_key}
        end

      block_key -> {palette, bbits, arr, block_key}
    end
  end

end

defimpl String.Chars, for: McChunk.Section do
  def to_string(nil), do: "#Section<empty>"
  def to_string(%McChunk.Section{y: y, block_bits: block_bits, palette: palette}) do
    "#Section<y=#{y}, #{block_bits} bits, palette=#{inspect palette}>"
  end
end
