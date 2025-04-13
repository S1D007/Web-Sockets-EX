defmodule WebsocketApp.Cluster do
  @moduledoc """
  Cluster configuration for WebsocketApp.
  Uses libcluster to enable automatic node discovery and clustering in Kubernetes.
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    topologies = get_topologies()

    children = [
      {Cluster.Supervisor, [topologies, [name: WebsocketApp.ClusterSupervisor]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end


  defp get_topologies do
    case Application.get_env(:websocket_app, :environment) do
      :prod ->

        [
          websocket_app_k8s: [
            strategy: Cluster.Strategy.Kubernetes,
            config: [
              mode: :dns,
              kubernetes_node_basename: "websocket-app",
              kubernetes_selector: "app=websocket-app",
              kubernetes_namespace: "websocket-app",
              polling_interval: 10_000
            ]
          ]
        ]

      :dev ->

        [
          websocket_app_local: [
            strategy: Cluster.Strategy.Epmd,
            config: [
              hosts: [
                :"node1@127.0.0.1",
                :"node2@127.0.0.1"
              ]
            ]
          ]
        ]

      _ ->
        []
    end
  end
end
