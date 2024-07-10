defmodule HayCluster do
  @moduledoc """
  """

  alias HayCluster.Server

  @doc """
  Starts the current node as a distributed node with the name of `:"manager@127.0.0.1"`
  """
  @spec start_distribution() :: {:ok, pid()}
  def start_distribution(), do: :net_kernel.start([:"manager@127.0.0.1"])

  @doc """
  Starts multiple child nodes and return node names for further use
  """
  @spec start_nodes(atom(), pos_integer(), Keyword.t()) :: [atom()]
  def start_nodes(prefix, amount, opts \\ []), do: Server.start_nodes(prefix, amount, opts)

  @doc """
  Stops the nodes
  """
  @spec stop_nodes([atom()]) :: :ok
  def stop_nodes(nodes) do
    nodes
    |> List.wrap()
    |> Server.stop_nodes()
  end
end
