defmodule McChunk.Test.Utils do
  use ExUnit.Case, async: true
  import McChunk.Utils

  test "Utils.pos3_to_index" do
    for pos <- [{0, -1, 0}, {0, -999, 0}, {0, 256, 0}, {0, 999, 0}] do
      assert_raise FunctionClauseError, fn ->
        pos3_to_index(pos)
      end
    end
    for pos <- [{0, 0, 0}, {0, 16, 64}, {-16, 64, -32}] do
      assert 0 == pos3_to_index(pos)
    end
    for pos <- [{15, 31, 63}, {-1, 255, -65}] do
      assert 4095 == pos3_to_index(pos)
    end
  end

  # TODO pos2_to_index
  # TODO Utils.idmeta_to_data
  # TODO Utils.data_to_idmeta
  # TODO Utils.mod

end
