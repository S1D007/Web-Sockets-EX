import Config

# Configure production-ready settings for Kubernetes deployment
config :websocket_app, WebsocketAppWeb.Endpoint,
  server: true,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [
    host: System.get_env("PHX_HOST") || "localhost",
    port: String.to_integer(System.get_env("PHX_PORT") || "80")
  ],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  check_origin: [
    "https://#{System.get_env("PHX_HOST") || "localhost"}",
    "https://*.#{System.get_env("PHX_HOST") || "localhost"}"
  ]

# Set log level to warning in production
config :logger, level: :warning

# Configure structured JSON logging for better parsing in log aggregation systems
config :logger, :console,
  format: {Logger.Formatter, :format},
  metadata: [:request_id, :trace_id, :span_id]

# Enable JSON logging if configured
if System.get_env("ENABLE_JSON_LOGGING", "false") == "true" do
  config :logger, backends: [LoggerJSON]

  config :logger_json, :backend,
    metadata: [:request_id, :trace_id, :span_id, :user_id, :remote_ip],
    formatter: LoggerJSON.Formatters.GoogleCloudLogger
end

# Configure the database connection
config :websocket_app, WebsocketApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
  ssl: String.to_existing_atom(System.get_env("DB_SSL", "false")),
  socket_options: if(System.get_env("DB_IPV6", "false") == "true", do: [:inet6], else: []),
  queue_target: 5000,
  queue_interval: 5000

# Enable tracing with OpenTelemetry
config :websocket_app, :enable_tracing, true

config :opentelemetry, :processors,
  otel_batch_processor: %{
    exporter: {:opentelemetry_exporter, %{endpoints: ["http://jaeger:14268/api/traces"]}}
  }

# DNS Cluster Configuration
config :websocket_app, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY", "websocket-app-headless.websocket-app.svc.cluster.local")

# Configure distributed Presence for WebSocket tracking
config :websocket_app, WebsocketAppWeb.Presence,
  pubsub_server: WebsocketApp.PubSub

# Configure Phoenix to use Redis PubSub in production for distribution
if System.get_env("USE_REDIS_PUBSUB", "true") == "true" do

  config :phoenix,
    pubsub_server: WebsocketApp.PubSub,
    static_compressor: :gzip


  config :websocket_app, :pubsub_type, WebsocketApp.PubSubRedis
else
  config :phoenix,
    pubsub_server: WebsocketApp.PubSub


  config :websocket_app, :pubsub_type, {Phoenix.PubSub, name: WebsocketApp.PubSub}
end

# Configure connection draining for graceful pod termination
config :websocket_app, :connection_draining,
  enabled: true,
  drain_timeout_ms: 30_000

# Set environment to production
config :websocket_app, :environment, :prod
