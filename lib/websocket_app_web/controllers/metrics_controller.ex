defmodule WebsocketAppWeb.MetricsController do
  use WebsocketAppWeb, :controller

  @doc """
  Exports Prometheus metrics in the format that Prometheus can scrape
  """
  def index(conn, _params) do

    metrics_data = Prometheus.Format.Text.format()


    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics_data)
  end
end
