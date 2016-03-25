defmodule McChunk.Section do
  import McChunk.Varint
  alias McChunk.Palette

  defstruct y: 0, palette: [0], block_bits: 1,
            block_data: <<0::4096>>,
            block_light: <<0::4096*4>>,
            sky_light: <<0::4096*4>>

  def decode(y, data) do
    <<block_bits::8, data::binary>> = data
    {palette, data} = case block_bits do
      0 -> {[], data}
      _ -> Palette.decode(data)
    end

    block_bits = if block_bits == 0 do 13 else block_bits end

    {data_nlongs, data} = decode_varint(data)
    data_nbits = data_nlongs * 8

    <<block_data::binary-size(data_nbits),
      block_light::binary-size(2048),
      data::binary>> = data

    # TODO no sky light in the nether
    <<sky_light::binary-size(2048), data::binary>> = data

    # TODO use block_bits for decoding block_data

    {%__MODULE__{y: y, palette: palette, block_bits: block_bits,
      block_data: block_data, block_light: block_light, sky_light: sky_light}, data}
  end

  def encode(%__MODULE__{palette: palette, block_bits: block_bits,
    block_data: block_data, block_light: block_light, sky_light: sky_light}) do
    <<block_bits>>
    <> Palette.encode(palette)
    <> encode_varint(div(byte_size(block_data), 8))
    <> block_data
    <> block_light
    <> sky_light
  end

end

defimpl String.Chars, for: McChunk.Section do
  def to_string(%McChunk.Section{y: y, block_bits: block_bits, palette: palette}) do
    "#Section<y=#{y}, #{block_bits} bits, palette=#{inspect palette}>"
  end
end
