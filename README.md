# libcluster_tailscale

This library adds a `libcluster` strategy for discovering and connecting Elixir nodes over Tailscale.

## Installation

The package can be installed by adding `libcluster_tailscale` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libcluster_tailscale, "~> 0.1.0"}
  ]
end
```

## Config

Configure your `libcluster` topology with the following config.

```elixir
config :libcluster,
  topologies: [
    tailscale: [
      strategy: Cluster.Strategy.Tailscale,
      config: [
        authkey: "tskey-api-xxx-yyy",
        tailnet: "example.com",
        hostname: "app.example.com",
        appname: "app"
      ]
    ]
  ]
```

## Example Phoenix Application

Let us say we're deploying a phoenix application called `hello`.

When you bring your tailscale service up on your node, provide a `hostname` that is consistent across your cluster and this strategy can then find all the IP addresses on your Tailnet belonging to that service and automatically cluster them together.

```sh
tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=hello-app
```

Configure your release to use the tailscale IP address as part of the node name:

```sh
ip=$(tailscale ip --4)
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=<%= @release.name %>@$ip
```

Then configure your cluster as follows

```elixir
config :libcluster,
  topologies: [
    tailscale: [
      strategy: Cluster.Strategy.Tailscale,
      config: [
        authkey: "tskey-api-xxx-yyy",
        tailnet: "example.com",
        hostname: "hello-app",
        appname: "hello"
      ]
    ]
  ]
```
