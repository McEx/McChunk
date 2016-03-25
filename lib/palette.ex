defmodule McChunk.Palette do
  alias McProtocol.DataTypes.Decode
  alias McProtocol.DataTypes.Encode

  @spec decode(binary) :: {[integer], binary}
  def decode(data) do
    with {:ok, {palette_len, data}} <- Decode.varint?(data),
    do: decode(palette_len, data)
  end

  defp decode(0, data), do: {[], data}
  defp decode(n, data) do
    {val, data} = Decode.varint(data)
    {vals, data} = decode(n-1, data)
    {[val | vals], data}
  end

  def encode(palette) do
    # TODO could use reduce for this
    {data, len} = encode_helper(palette)
    Encode.varint(len) <> data
  end

  defp encode_helper([]), do: {"", 0}
  defp encode_helper([val | vals]) do
    {data, len} = encode_helper(vals)
    {Encode.varint(val) <> data, len+1}
  end

end
