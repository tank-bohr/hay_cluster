[![Elixir CI](https://github.com/tank-bohr/hay_cluster/actions/workflows/elixir.yml/badge.svg)](https://github.com/tank-bohr/hay_cluster/actions/workflows/elixir.yml)

# HayCluster

A tool for testing your code in the clustered environment. Focused on correct coverage counting.

Highly inspired by [LocalCluster](https://github.com/whitfin/local-cluster).

## Usage

- Add hay_cluster to your list of dependencies in mix.exs:

```elixir
defp deps do
  [
    {:hay_cluster, "~> 0.1.0"}
  ]
end
```

- Update test_helper.exs

```elixir
HayCluster.start_distribution()
Application.ensure_all_started(:my_app)
ExUnit.start()
```

- Introduce alias to run test without starting an application:

```elixir
defp aliases do
  [
    test: "test --no-start"
  ]
end
```
