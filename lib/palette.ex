defmodule Palette do
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
    "" # XXX
  end

end
