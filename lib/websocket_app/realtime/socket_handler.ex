defmodule WebsocketApp.Realtime.SocketHandler do
  use GenServer
  require Logger

  def start_link({socket_id, user_id}) do
    GenServer.start_link(__MODULE__, {socket_id, user_id}, name: via_tuple(socket_id))
  end

  def init({socket_id, user_id}) do
    Process.flag(:trap_exit, true)
    {:ok, %{socket_id: socket_id, user_id: user_id, last_ping: DateTime.utc_now()}}
  end

  def handle_info(:check_health, state) do
    if DateTime.diff(DateTime.utc_now(), state.last_ping) > 60 do
      {:stop, :normal, state}
    else
      Process.send_after(self(), :check_health, 30_000)
      {:noreply, state}
    end
  end

  def handle_cast({:ping, timestamp}, state) do
    {:noreply, %{state | last_ping: timestamp}}
  end

  def terminate(reason, state) do
    Logger.info("Socket #{state.socket_id} terminated: #{inspect(reason)}")
    :ok
  end

  defp via_tuple(socket_id) do
    {:via, Registry, {WebsocketApp.SocketRegistry, socket_id}}
  end
end
