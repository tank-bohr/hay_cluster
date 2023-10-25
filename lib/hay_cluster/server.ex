defmodule HayClusterServer do
  use GenServer

  @this {:global, __MODULE__}

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(_opts) do
    with {:error, {:already_started, _pid}} <- GenServer.start_link(__MODULE__, [], name: @this) do
      :ignore
    end
  end

  @spec start_nodes(pos_integer(), Keyword.t()) :: [atom()]
  def start_nodes(prefix, amount, opts) do
    names = Enum.map(1..amount, fn _idx -> :peer.random_name(prefix) end)
    GenServer.call(@this, {:start_nodes, names, amount, opts})
  end

  @impl GenServer
  def init([]) do
    {:ok, %{nodes: []}}
  end

  @impl GenServer
  def handle_call({:start_nodes, names, amount, opts}, _from, state) do
    nodes =
      names
      |> Enum.map(fn name ->
        :peer.start(%{
          name: name,
          longnames: true,
          host: "127.0.0.1",
          peer_down: :continue
        })
      end)
      |> tap(&setup_nodes/1)
      |> tap(&transfer_environment/1)
      |> tap(&start_applications/1)
      |> tap(&add_coverage/1)

    {:reply, nodes, Map.update!(state, :nodes, fn n -> n ++ nodes end)}
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
    Application.started_applications()
    |> Enum.map(fn {name, _descr, _version} -> name end)
    |> Enum.each(&Application.ensure_all_started/1)
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
