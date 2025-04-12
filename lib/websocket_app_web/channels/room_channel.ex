defmodule WebsocketAppWeb.RoomChannel do
  use Phoenix.Channel

  alias WebsocketAppWeb.Presence

  def join("room:" <> room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: DateTime.utc_now(),
      room_id: socket.assigns.room_id
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in("message:new", %{"body" => body}, socket) do
    message = %{
      id: System.unique_integer([:positive]),
      user_id: socket.assigns.user_id,
      room_id: socket.assigns.room_id,
      body: body,
      timestamp: DateTime.utc_now()
    }

    broadcast!(socket, "message:new", message)
    {:noreply, socket}
  end

  def handle_in("typing", %{"typing" => typing}, socket) do
    {:ok, _} = Presence.update(socket, socket.assigns.user_id, fn meta ->
      Map.put(meta, :typing, typing)
    end)
    {:noreply, socket}
  end
end
