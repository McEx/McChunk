defmodule McChunk.BitArray do
  use Bitwise

  @behaviour McChunk.BlockStore

  def new(num_longs), do: :array.new(num_longs, default: 0)

  def decode(data, num_longs) do
    arr = :array.new(num_longs)
    Enum.reduce(0..(num_longs - 1), {arr, data}, fn i, {arr, data} ->
      <<long_val::big-integer-size(64), data::binary>> = data
      {:array.set(i, long_val, arr), data}
    end)
  end

  def encode(arr) do
    for val <- :array.to_list(arr), do: <<val::big-integer-size(64)>>
  end

  def get(arr, bbits, index) do
    max_value = (1 <<< bbits) - 1
    start_long = div(index * bbits, 64)
    start_offset = rem(index * bbits, 64)
    end_long = div((index + 1) * bbits - 1, 64)

    start_val = :array.get(start_long, arr) >>> start_offset

    if start_long == end_long do
      start_val
    else
      end_offset = 64 - start_offset
      end_val = :array.get(end_long, arr) <<< end_offset

      (start_val ||| end_val)
    end &&& max_value
  end

  def set(arr, bbits, index, value) do
    max_value = (1 <<< bbits) - 1
    start_long = div(index * bbits, 64)
    start_offset = rem(index * bbits, 64)
    end_long = div((index + 1) * bbits - 1, 64)

    start_val_a = :array.get(start_long, arr) &&& bnot(max_value <<< start_offset)
    start_val_b = (value &&& max_value) <<< start_offset
    arr = :array.set(start_long, start_val_a ||| start_val_b, arr)

    if start_long != end_long do
      end_offset = 64 - start_offset
      j1 = bbits - end_offset
      end_val_a = :array.get(end_long, arr) >>> j1 <<< j1
      end_val_b = (value &&& max_value) >>> end_offset

      :array.set(end_long, end_val_a ||| end_val_b, arr)
    else
      arr
    end
  end

end
