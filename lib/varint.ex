defmodule McChunk.Varint do
  use Bitwise

  @spec decode_varint(binary) :: {integer, binary}
  def decode_varint(data) do
    {:ok, resp} = decode_varint(data, 0, 0)
    resp
  end

  defp decode_varint(<<1::1, curr::7, rest::binary>>, num, acc) when num < (64 - 7) do
    decode_varint(rest, num + 7, (curr <<< num) + acc)
  end
  defp decode_varint(<<0::1, curr::7, rest::binary>>, num, acc) do
    {:ok, {(curr <<< num) + acc, rest}}
  end
  defp decode_varint(_, num, _) when num >= (64 - 7), do: :too_big
  defp decode_varint("", _, _), do: :incomplete
  defp decode_varint(_, _, _), do: :error

  def encode_varint(n) when n <= 127, do: <<n>>
  def encode_varint(n) when n >= 128 do
    <<1::1, (n &&& 127)::7, encode_varint(n >>> 7)::binary>>
  end

end
