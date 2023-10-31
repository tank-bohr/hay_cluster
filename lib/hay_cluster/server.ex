defmodule HayCluster.Server do
  use GenServer

  @this {:global, __MODULE__}

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(_opts) do
    with {:error, {:already_started, _pid}} <- GenServer.start_link(__MODULE__, [], name: @this) do
      :ignore
    end
  end

  @spec start_nodes(String.t(), pos_integer(), Keyword.t()) :: [atom()]
  def start_nodes(prefix, amount, opts) do
    names = Enum.map(1..amount, fn _idx -> :peer.random_name(prefix) end)
    GenServer.call(@this, {:start_nodes, names, opts})
  end

  def stop_nodes(nodes) do
    GenServer.call(@this, {:stop_nodes, nodes})
  end

  @impl GenServer
  def init([]) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:start_nodes, names, _opts}, _from, state) do
    mapping =
      names
      |> Enum.map(fn name ->
        :peer.start(%{
          name: name,
          longnames: true,
          host: '127.0.0.1',
          peer_down: :continue
        })
      end)
      |> Enum.into(%{}, fn {:ok, pid, name} -> {name, pid} end)

    nodes =
      mapping
      |> Map.keys()
      |> tap(&setup_nodes/1)
      |> tap(&transfer_environment/1)
      |> tap(&start_applications/1)
      |> tap(&add_coverage/1)

    {:reply, nodes, Map.merge(state, mapping)}
  end

  def handle_call({:stop_nodes, nodes}, _from, state) do
    pids =
      nodes
      |> Enum.map(fn node -> Map.get(state, node) end)
      |> Enum.reject(&is_nil/1)

    {:reply, Enum.each(pids, &:peer.stop/1), state}
  end

  defp setup_nodes(nodes) do
    :erpc.multicall(nodes, :code, :add_paths, [:code.get_path()])
    :erpc.multicall(nodes, Application, :ensure_all_started, [:mix])
    :erpc.multicall(nodes, Application, :ensure_all_started, [:logger])
    :erpc.multicall(nodes, Logger, :configure, [[level: Logger.level()]])
    :erpc.multicall(nodes, Mix, :env, [Mix.env()])
    :erpc.multicall(nodes, :global, :sync, [])
  end

  defp transfer_environment(nodes) do
    Application.loaded_applications()
    |> Enum.map(fn {name, _descr, _version} -> name end)
    |> Enum.each(fn app ->
      app
      |> Application.get_all_env()
      |> Enum.each(fn {key, value} ->
        :erpc.multicall(nodes, Application, :put_env, [app, key, value])
      end)
    end)
  end

  defp start_applications(nodes) do
    Enum.each(Application.started_applications(), fn {name, _descr, _version} ->
      :erpc.multicall(nodes, Application, :ensure_all_started, [name])
    end)
  end

  def add_coverage(nodes) do
    case Process.whereis(:cover_server) do
      nil ->
        {:ok, []}

      pid when is_pid(pid) ->
        :cover.start(nodes)
    end
  end
end
