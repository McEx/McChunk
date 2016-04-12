defmodule McChunk.Utils do
  use Bitwise

  # TODO helper functions for bit masks

  def pos2_to_index({x, z}), do: mod(x, 16) + 16 * mod(z, 16)

  def pos3_to_index({x, y, z}) when y >= 0 and y < 256 do
    mod(x, 16) + 16 * mod(z, 16) + 256 * mod(y, 16)
  end

  def mod(x, y) when x > 0, do: rem(x, y)
  def mod(x, y) when x < 0, do: rem(y + rem(x, y), y)
  def mod(0, _), do: 0

  def idmeta_to_data({id, meta}), do: (id <<< 4) ||| meta
  def data_to_idmeta(data), do: {data >>> 4, data &&& 15}

end
