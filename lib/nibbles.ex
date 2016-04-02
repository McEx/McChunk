defmodule McChunk.Nibbles do
  @moduledoc """
  De-/serialization and accessing half-byte-per-entry arrays.

  Data is stored as an erlang array of bytes, two nibbles per entry.

  TODO there should be a param to make the entries larger
  """

  use Bitwise

  def new(num_nibbles, default \\ 0),
    do: :array.new(div(num_nibbles, 2), default: default)

  def decode(data, num_nibbles) do
    arr = :array.new(div(num_nibbles, 2))
    Enum.reduce(0..(div(num_nibbles, 2) - 1), {arr, data}, fn i, {arr, data} ->
      <<bin::8, data::binary>> = data
      {:array.set(i, bin, arr), data}
    end)
  end

  def encode(data) do
    :array.to_list(data)
  end

  def get(arr, index) do
    val = :array.get(div(index, 2), arr)
    case rem(index, 2) do
      0 -> val &&& 0xf
      1 -> (val >>> 4) &&& 0xf
    end
  end

  def set(arr, index, val) do
    old = :array.get(div(index, 2), arr)
    entry = case rem(index, 2) do
      0 -> val ||| (0xf0 &&& old)
      1 -> (val <<< 4) ||| (0x0f &&& old)
    end
    :array.set(div(index, 2), entry, arr)
  end

end
