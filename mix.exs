defmodule McChunk.Mixfile do
  use Mix.Project

  def project do
    [app: :mc_chunk,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     rustler_crates: ["mc_chunk_native"],
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:benchfella, "~> 0.3.0", only: :dev},
      {:credo, "~> 0.3", only: :dev},
    ]
  end

end
