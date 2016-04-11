defmodule McChunk.BlockStore do

  @type block_store :: any
  @type num_longs :: pos_integer
  @type bbits :: pos_integer
  @type index :: non_neg_integer
  @type value :: non_neg_integer

  @callback new(num_longs) :: block_store
  @callback decode(binary, num_longs) :: block_store
  @callback encode(block_store) :: binary
  @callback get(block_store, bbits, index) :: value
  @callback set(block_store, bbits, index, value) :: block_store

  @block_store Application.get_env(:mc_chunk, :block_store)

  def new(num_longs),
    do: apply(@block_store, :new, [num_longs])
  def decode(binary, num_longs),
    do: apply(@block_store, :decode, [binary, num_longs])
  def encode(block_store),
    do: apply(@block_store, :encode, [block_store])
  def get(block_store, bbits, index),
    do: apply(@block_store, :get, [block_store, bbits, index])
  def set(block_store, bbits, index, value),
    do: apply(@block_store, :set, [block_store, bbits, index, value])

end
