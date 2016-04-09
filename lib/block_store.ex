defmodule McChunk.BlockStore do

  @type block_store :: any
  @type len :: pos_integer
  @type bbits :: pos_integer
  @type index :: non_neg_integer
  @type value :: non_neg_integer

  @callback new(len) :: block_store
  @callback decode(binary, len) :: block_store
  @callback encode(block_store) :: binary
  @callback get(block_store, bbits, index) :: value
  @callback set(block_store, bbits, index, value) :: block_store

end
