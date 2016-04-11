defmodule McChunk.Test.Utils do
  use ExUnit.Case, async: true
  import McChunk.Utils

  test "Utils.pos_to_index" do
    for pos <- [{0, -1, 0}, {0, -999, 0}, {0, 256, 0}, {0, 999, 0}] do
      assert_raise FunctionClauseError, fn ->
        pos_to_index(pos)
      end
    end
    for pos <- [{0, 0, 0}, {0, 16, 64}, {-16, 64, -32}] do
      assert 0 == pos_to_index(pos)
    end
    for pos <- [{15, 31, 63}, {-1, 255, -65}] do
      assert 4095 == pos_to_index(pos)
    end
  end

  test "Utils.idmeta_to_data" do
    # TODO
  end

  test "Utils.data_to_idmeta" do
    # TODO
  end

  test "Utils.mod" do
    # TODO
  end

end
