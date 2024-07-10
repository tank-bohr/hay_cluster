defmodule HayCluster.MixProject do
  use Mix.Project

  @name "HayCluster"
  @version "1.0.0"
  @repo_url "https://github.com/tank-bohr/hay_cluster"

  def project do
    [
      app: :hay_cluster,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "A tool for testing your code in the clustered environment",
      package: package(),
      deps: deps(),
      docs: docs(),
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

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      links: %{"GitHub" => @repo_url},
      licenses: ["MIT"]
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @repo_url,
      main: @name
    ]
  end
end
