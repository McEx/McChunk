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

  def encode([]), do: ""
  def encode(palette) do
    {data, len} = Enum.reduce palette, {"", 0}, fn val, {data, len} ->
      {data <> encode_varint(val), len+1}
    end
    encode_varint(len) <> data
  end

  def lookup(palette, block), do: Enum.find_index(palette, &(&1 == block))

  def block_bits([]), do: 1
  def block_bits([_]), do: 1
  def block_bits(palette) do
    trunc Float.ceil :math.log2 length palette
  end

end
