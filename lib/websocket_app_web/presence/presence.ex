defmodule WebsocketAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :websocket_app,
    pubsub_server: WebsocketApp.PubSub
end