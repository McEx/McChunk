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

end
