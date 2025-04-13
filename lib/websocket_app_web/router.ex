defmodule WebsocketAppWeb.Router do
  use WebsocketAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebsocketAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/health", WebsocketAppWeb do
    pipe_through :api

    get "/liveness", HealthController, :liveness
    get "/readiness", HealthController, :readiness
  end


  scope "/metrics", WebsocketAppWeb do
    pipe_through :api

    get "/", MetricsController, :index
  end

  scope "/", WebsocketAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end







  if Application.compile_env(:websocket_app, :dev_routes) do





    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WebsocketAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
