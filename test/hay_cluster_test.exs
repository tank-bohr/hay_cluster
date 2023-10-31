defmodule HayClusterTest do
  use ExUnit.Case

  test "creates and stops child nodes" do
    nodes = HayCluster.start_nodes(:child, 3)

    [node1, node2, node3] = nodes

    assert Node.ping(node1) == :pong
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    :ok = HayCluster.stop_nodes([node1])

    assert Node.ping(node1) == :pang
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    :ok = HayCluster.stop_nodes([node2, node3])

    assert Node.ping(node1) == :pang
    assert Node.ping(node2) == :pang
    assert Node.ping(node3) == :pang
  end

  test "load selected applications" do
    nodes = HayCluster.start_nodes(:child, 1, [
      applications: [
        :hay_cluster,
        :ex_unit,
        :no_real_app
      ]
    ])

    [node1] = nodes

    node1_apps =
      node1
      |> :erpc.call(Application, :loaded_applications, [])
      |> Enum.map(fn {app_name, _, _} -> app_name end)

    assert :hay_cluster in node1_apps
    assert :ex_unit in node1_apps
    assert (:no_real_app in node1_apps) == false

    :ok = HayCluster.stop_nodes(nodes)
  end

  test "spawns tasks directly on child nodes" do
    nodes = HayCluster.start_nodes(:spawn, 3, [
      files: [
        __ENV__.file
      ]
    ])

    [node1, node2, node3] = nodes

    assert Node.ping(node1) == :pong
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    caller = self()

    Node.spawn(node1, fn ->
      send(caller, :from_node_1)
    end)

    Node.spawn(node2, fn ->
      send(caller, :from_node_2)
    end)

    Node.spawn(node3, fn ->
      send(caller, :from_node_3)
    end)

    assert_receive :from_node_1
    assert_receive :from_node_2
    assert_receive :from_node_3
  end

  test "overriding environment variables on child nodes" do
    [node1] = HayCluster.start_nodes(:cluster_var_a, 1, [
      environment: [
        hay_cluster: [override: "test1"]
      ]
    ])

    [node2] = HayCluster.start_nodes(:cluster_var_b, 1, [
      environment: [
        hay_cluster: [override: "test2"]
      ]
    ])

    [node3] = HayCluster.start_nodes(:cluster_no_env, 1)

    node1_env = :erpc.call(node1, Application, :get_env, [:hay_cluster, :override])
    node2_env = :erpc.call(node2, Application, :get_env, [:hay_cluster, :override])
    node3_env = :erpc.call(node3, Application, :get_env, [:hay_cluster, :override])

    assert node1_env == "test1"
    assert node2_env == "test2"
    assert node3_env == Application.get_env(:hay_cluster, :override)
  end
end
