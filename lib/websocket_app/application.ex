defmodule WebsocketApp.Application do


  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    WebsocketAppWeb.Telemetry.PrometheusMetrics.setup()


    setup_opentelemetry()


    Application.put_env(:websocket_app, :environment, determine_environment())

    children = [

      WebsocketAppWeb.Telemetry,


      WebsocketApp.Repo,
      {DNSCluster, query: Application.get_env(:websocket_app, :dns_cluster_query) || :ignore},


      WebsocketApp.Cluster,


      {Phoenix.PubSub, name: WebsocketApp.PubSub},


      {Registry, keys: :unique, name: WebsocketApp.SocketRegistry},


      {Redix.Supervisor, redix_config()},


      WebsocketApp.Realtime.SocketSupervisor,
      WebsocketAppWeb.Presence,


      {Finch, name: WebsocketApp.Finch},


      setup_metrics_collector(),


      WebsocketAppWeb.Endpoint
    ]



    opts = [strategy: :one_for_one, name: WebsocketApp.Supervisor]
    Supervisor.start_link(children, opts)
  end



  @impl true
  def config_change(changed, _new, removed) do
    WebsocketAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end


  defp redix_config do
    uri = System.get_env("REDIS_URL", "redis://redis:6379")

    name = :redix_pool
    pool_size = String.to_integer(System.get_env("REDIS_POOL_SIZE", "10"))

    child_spec = Redix.child_spec(uri, name: name)

    %{
      name: {:local, name},
      worker_module: Redix,
      size: pool_size,
      max_overflow: 5,
      child_spec: child_spec
    }
  end


  defp setup_metrics_collector do

    {Task, fn ->
      :timer.sleep(10_000)
      WebsocketAppWeb.Telemetry.PrometheusMetrics.update_vm_metrics()
    end}
  end


  defp setup_opentelemetry do
    if Application.get_env(:websocket_app, :enable_tracing, false) do
      :opentelemetry.setup()

      :opentelemetry_phoenix.setup()

      :ok = :opentelemetry_exporter.init()
    end
  end


  defp determine_environment do
    case Mix.env() do
      :prod -> :prod
      :dev -> :dev
      _ -> :test
    end
  end
end
