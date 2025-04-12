defmodule WebsocketApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebsocketAppWeb.Telemetry,
      WebsocketApp.Repo,
      {DNSCluster, query: Application.get_env(:websocket_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WebsocketApp.PubSub},
      {Registry, keys: :unique, name: WebsocketApp.SocketRegistry},
      WebsocketApp.Realtime.SocketSupervisor,
      WebsocketAppWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: WebsocketApp.Finch},
      # Start a worker by calling: WebsocketApp.Worker.start_link(arg)
      # {WebsocketApp.Worker, arg},
      # Start to serve requests, typically the last entry
      WebsocketAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebsocketApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebsocketAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
