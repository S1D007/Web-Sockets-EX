defmodule WebsocketAppWeb.Telemetry.PrometheusMetrics do
  @moduledoc """
  Prometheus metrics integration for the WebSocket Application
  """

  use Prometheus.Metric


  def setup do

    Counter.declare(
      name: :phoenix_endpoint_requests_total,
      help: "Total number of requests handled by the Phoenix endpoint",
      labels: [:status, :method, :path]
    )

    Histogram.declare(
      name: :phoenix_endpoint_request_duration_milliseconds,
      help: "Request duration in milliseconds",
      labels: [:status, :method, :path],
      buckets: [10, 100, 500, 1000, 5000, 10_000]
    )


    Counter.declare(
      name: :phoenix_channel_joined_total,
      help: "Total number of channel joins",
      labels: [:channel]
    )

    Counter.declare(
      name: :phoenix_channel_left_total,
      help: "Total number of channel leaves",
      labels: [:channel]
    )

    Gauge.declare(
      name: :phoenix_channel_active_connections,
      help: "Number of active WebSocket connections",
      labels: [:channel]
    )


    Counter.declare(
      name: :ecto_queries_total,
      help: "Total number of database queries executed",
      labels: [:type, :status]
    )

    Histogram.declare(
      name: :ecto_query_duration_milliseconds,
      help: "Query execution time in milliseconds",
      labels: [:type],
      buckets: [1, 10, 100, 500, 1000, 5000]
    )


    Gauge.declare(
      name: :vm_memory_total_bytes,
      help: "Total memory allocated by the Erlang VM in bytes"
    )

    Gauge.declare(
      name: :vm_total_processes,
      help: "Total number of Erlang processes"
    )
  end


  def handle_event([:phoenix, :endpoint, :stop], %{duration: duration} = measurements, %{conn: conn}, _config) do
    labels = [
      Integer.to_string(conn.status),
      conn.method,
      Phoenix.Router.route_info(conn).route
    ]

    Counter.inc(name: :phoenix_endpoint_requests_total, labels: labels)
    Histogram.observe([
      name: :phoenix_endpoint_request_duration_milliseconds,
      labels: labels
    ], duration / 1_000_000)
  end

  def handle_event([:phoenix, :channel, :join], _measurements, %{result: :ok, socket: socket}, _config) do
    channel = socket.channel
    Counter.inc(name: :phoenix_channel_joined_total, labels: [channel])
    Gauge.inc(name: :phoenix_channel_active_connections, labels: [channel])
  end

  def handle_event([:phoenix, :channel, :leave], _measurements, %{socket: socket}, _config) do
    channel = socket.channel
    Counter.inc(name: :phoenix_channel_left_total, labels: [channel])
    Gauge.dec(name: :phoenix_channel_active_connections, labels: [channel])
  end

  def handle_event([:ecto, :query], %{total_time: total_time}, metadata, _config) do

    status = if metadata.result == :ok, do: "success", else: "error"
    type = metadata.source

    Counter.inc(name: :ecto_queries_total, labels: [type, status])
    Histogram.observe([
      name: :ecto_query_duration_milliseconds,
      labels: [type]
    ], total_time / 1_000_000)
  end


  def update_vm_metrics do
    memory = :erlang.memory()
    total_memory = memory[:total]
    Gauge.set([name: :vm_memory_total_bytes], total_memory)

    process_count = :erlang.system_info(:process_count)
    Gauge.set([name: :vm_total_processes], process_count)
  end
end
