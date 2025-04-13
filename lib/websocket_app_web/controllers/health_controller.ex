defmodule WebsocketAppWeb.HealthController do
  use WebsocketAppWeb, :controller

  @doc """
  Liveness probe - checks if the application is running and responsive
  """
  def liveness(conn, _params) do

    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end

  @doc """
  Readiness probe - checks if the application can accept requests
  Dependencies (database, redis) are checked
  """
  def readiness(conn, _params) do

    db_status =
      try do
        WebsocketApp.Repo.query!("SELECT 1")
        :ok
      rescue
        _ -> :error
      end


    redis_status =
      if Code.ensure_loaded?(Redix) do
        try do
          {:ok, conn} = Redix.start_link(System.get_env("REDIS_URL", "redis://redis:6379"))
          {:ok, "PONG"} = Redix.command(conn, ["PING"])
          :ok
        rescue
          _ -> :error
        end
      else
        :not_configured
      end

    status = if db_status == :ok, do: 200, else: 503


    conn
    |> put_status(status)
    |> json(%{
      status: if(status == 200, do: "ok", else: "error"),
      database: db_status,
      redis: redis_status,
      timestamp: DateTime.utc_now()
    })
  end
end
