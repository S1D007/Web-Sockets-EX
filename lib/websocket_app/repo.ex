defmodule WebsocketApp.Repo do
  use Ecto.Repo,
    otp_app: :websocket_app,
    adapter: Ecto.Adapters.Postgres
end
