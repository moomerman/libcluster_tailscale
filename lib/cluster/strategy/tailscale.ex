defmodule Cluster.Strategy.Tailscale do
  @moduledoc """
  Cluster strategy for connecting Elixir nodes over Tailscale.

      config :libcluster,
        topologies: [
          tailscale: [
            strategy: #{__MODULE__},
            config: [
              authkey: "",
              tailnet: "",
              hostname: "",
              appname: ""
            ]
          ]
        ]

  """
  use GenServer
  alias Cluster.Strategy.State

  @polling_interval 30_000
  @endpoint "api.tailscale.com/api/v2"

  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @impl true
  def init([%State{meta: nil} = state]) do
    init([%State{state | :meta => MapSet.new()}])
  end

  def init([%State{} = state]) do
    {:ok, load(state)}
  end

  @impl true
  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end

  def handle_info(:load, %State{} = state) do
    {:noreply, load(state)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp load(%State{} = state) do
    nodes =
      state
      |> get_nodes()
      |> disconnect_nodes(state)
      |> connect_nodes(state)

    Process.send_after(self(), :load, @polling_interval)
    %{state | meta: nodes}
  end

  defp get_nodes(%State{config: config}) do
    tailnet = Keyword.fetch!(config, :tailnet)
    hostname = Keyword.fetch!(config, :hostname)
    appname = Keyword.fetch!(config, :appname)
    authkey = Keyword.fetch!(config, :authkey)

    list_devices(tailnet, authkey)
    |> Enum.filter(&(&1["hostname"] == hostname))
    |> Enum.map(&List.first(&1["addresses"]))
    |> Enum.map(&"#{appname}@#{&1}")
    |> Enum.map(&String.to_atom/1)
    |> MapSet.new()
  end

  defp disconnect_nodes(nodes, %State{} = state) do
    removed = MapSet.difference(state.meta, nodes)

    case Cluster.Strategy.disconnect_nodes(
           state.topology,
           state.disconnect,
           state.list_nodes,
           MapSet.to_list(removed)
         ) do
      :ok ->
        nodes

      {:error, bad_nodes} ->
        # Add back the nodes we couldn't remove
        Enum.reduce(bad_nodes, nodes, fn {n, _}, acc ->
          MapSet.put(acc, n)
        end)
    end
  end

  defp connect_nodes(nodes, %State{} = state) do
    case Cluster.Strategy.connect_nodes(
           state.topology,
           state.connect,
           state.list_nodes,
           MapSet.to_list(nodes)
         ) do
      :ok ->
        nodes

      {:error, bad_nodes} ->
        # Remove the nodes we couldn't add
        Enum.reduce(bad_nodes, nodes, fn {n, _}, acc ->
          MapSet.delete(acc, n)
        end)
    end
  end

  def list_devices(tailnet, authkey) do
    case get("/tailnet/#{tailnet}/devices", authkey) do
      {:ok, devices} -> devices["devices"]
      _ -> []
    end
  end

  def get(path, authkey) do
    case :httpc.request(:get, {'https://#{authkey}:@#{@endpoint}/#{path}', []}, [], []) do
      {:ok, {{_version, 200, _status}, _headers, body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, {{_version, code, status}, _headers, body}} ->
        {:warn, [code, status, body]}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
