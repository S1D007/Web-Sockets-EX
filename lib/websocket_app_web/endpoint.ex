defmodule WebsocketAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :websocket_app




  @session_options [
    store: :cookie,
    key: "_websocket_app_key",
    signing_salt: "wZ7rvYsk",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]





  plug Plug.Static,
    at: "/",
    from: :websocket_app,
    gzip: false,
    only: WebsocketAppWeb.static_paths()



  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :websocket_app
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug WebsocketAppWeb.Router
end
