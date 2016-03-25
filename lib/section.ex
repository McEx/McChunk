defmodule McChunk.Section do
  alias McProtocol.DataTypes.Decode
  alias McProtocol.DataTypes.Encode
  alias McChunk.Palette
  alias McChunk.Section

  defstruct y: 0, palette: [0],
            block_data: <<0::size(4096)>>,
            block_light: <<0::size(16384)>>,
            sky_light: <<0::size(16384)>>

  def decode(y, data) do
    <<block_bits::size(8), data::binary>> = data
    {palette, data} = case block_bits do
      0 -> {[], data}
      _ -> Palette.decode(data)
    end

    block_bits = if block_bits == 0 do 13 else block_bits end

    {data_nlongs, data} = Decode.varint(data)
    data_nbits = data_nlongs * 8 * 8
    <<block_data::size(data_nbits), data::binary>> = data

    # TODO use block_bits for decoding block_data

    <<block_light::size(16384), data::binary>> = data
    <<sky_light::size(16384), data::binary>> = data

    {%Section{y: y, palette: palette, block_data: block_data,
              block_light: block_light, sky_light: sky_light}, data}
  end

  def encode(%Section{y: y, palette: palette, block_data: block_data,
             block_light: block_light, sky_light: sky_light}) do
    "" # XXX
  end

end

defimpl String.Chars, for: McChunk.Section do
  def to_string(%McChunk.Section{y: y, palette: palette, block_data: block_data,
                block_light: block_light, sky_light: sky_light}) do
    "#Section<at y=#{y}, #{length(palette)} palette entries>"
  end
end
