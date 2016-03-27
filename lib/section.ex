defmodule McChunk.Section do
  use Bitwise
  import McChunk.Varint
  alias McChunk.Palette

  defstruct y: 0, palette: [0], block_bits: 1,
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
    data_nbits = num_longs * 8

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

  def get_block(%__MODULE__{palette: palette, block_bits: block_bits,
    block_array: block_array}, index) do
    {uses_palette, block_bits} = case block_bits do
      0 -> {false, 13}
      bb -> {true, bb}
    end
    max_value = (1 <<< block_bits) - 1
    start_long = div(index * block_bits, 64)
    start_offset = rem(index * block_bits, 64)
    end_long = div((index + 1) * block_bits - 1, 64)

    start_val = :array.get(start_long, block_array) >>> start_offset

    block = if start_long == end_long do
      start_val
    else
      end_offset = 64 - start_offset
      end_val = :array.get(end_long, block_array) <<< end_offset

      (start_val ||| end_val)
    end &&& max_value

    if uses_palette do
      Enum.at(palette, block)
    else
      block # already global palette
    end
  end

  def set_block(section, index, block) do
    block_bits = section.block_bits
    block_array = section.block_array

    {uses_palette, block_bits} = case block_bits do
      0 -> {false, 13}
      bb -> {true, bb}
    end

    block = if uses_palette do
      Enum.find_index(section.palette, &(&1 == block))
      # TODO if new block, grow palette and block_array
    else
      block
    end

    max_value = (1 <<< block_bits) - 1
    start_long = div(index * block_bits, 64)
    start_offset = rem(index * block_bits, 64)
    end_long = div((index + 1) * block_bits - 1, 64)

    start_val_a = :array.get(start_long, block_array) &&& bnot(max_value <<< start_offset)
    start_val_b = (block &&& max_value) <<< start_offset
    block_array = :array.set(start_long, start_val_a ||| start_val_b, block_array)

    block_array = if start_long != end_long do
      end_offset = 64 - start_offset
      j1 = block_bits - end_offset
      end_val_a = :array.get(end_long, block_array) >>> j1 <<< j1
      end_val_b = (block &&& max_value) >>> end_offset

      :array.set(end_long, end_val_a ||| end_val_b, block_array)
    else
      block_array
    end

    %__MODULE__{section | block_array: block_array}
  end

end

defimpl String.Chars, for: McChunk.Section do
  def to_string(%McChunk.Section{y: y, block_bits: block_bits, palette: palette}) do
    "#Section<y=#{y}, #{block_bits} bits, palette=#{inspect palette}>"
  end
end
