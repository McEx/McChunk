ExUnit.start()

defmodule McChunk.Test.Helpers do
	def repeat(vals, len), do: vals |> Stream.cycle |> Enum.take(len)
end
