defmodule McChunk.Palette do
  import McChunk.Varint

  def decode(data) do
    {palette_len, data} = decode_varint(data)
    decode(data, palette_len)
  end

  defp decode(data, 0), do: {[], data}
  defp decode(data, n) do
    {val, data} = decode_varint(data)
    {vals, data} = decode(data, n - 1)
    {[val | vals], data}
  end

  def encode(palette) do
    values = for val <- palette, do: encode_varint(val)
    [encode_varint(length values), values]
  end

  def lookup(palette, block), do: Enum.find_index(palette, &(&1 == block))

  def block_bits([]), do: 4
  def block_bits([_]), do: 4
  def block_bits(palette) do
    palette
    |> length
    |> :math.log2
    |> Float.ceil
    |> trunc
    |> max(4)
    |> min(8)
  end

end
