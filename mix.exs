defmodule HayCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :hay_cluster,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: [],
      aliases: [
        test: "test --no-start"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :tools],
      mod: {HayCluster.Application, []}
    ]
  end
end
