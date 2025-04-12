defmodule WebsocketAppWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", WebsocketAppWeb.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: 45_000,
    check_origin: false

  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end