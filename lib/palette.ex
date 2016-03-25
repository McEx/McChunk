defmodule McChunk.Palette do
  import McChunk.Varint

  @spec decode(binary) :: {[integer], binary}
  def decode(data) do
    {palette_len, data} = decode_varint(data)
    decode(palette_len, data)
  end

  defp decode(0, data), do: {[], data}
  defp decode(n, data) do
    {val, data} = decode_varint(data)
    {vals, data} = decode(n-1, data)
    {[val | vals], data}
  end

  def encode(palette) do
    {data, len} = Enum.reduce palette, {"", 0}, fn val, {data, len} ->
      {encode_varint(val) <> data, len+1}
    end
    encode_varint(len) <> data
  end

end
