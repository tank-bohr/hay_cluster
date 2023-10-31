defmodule HayCluster do
  @moduledoc false

  alias HayCluster.Server

  @spec start_distribution() :: {:ok, pid()}
  def start_distribution(), do: :net_kernel.start([:"manager@127.0.0.1"])

  @spec start_nodes(String.t(), pos_integer(), Keyword.t()) :: [atom()]
  def start_nodes(prefix, amount, opts \\ []), do: Server.start_nodes(prefix, amount, opts)

  @spec stop_nodes([atom()]) :: :ok
  def stop_nodes(nodes), do: Server.stop_nodes(nodes)
end
