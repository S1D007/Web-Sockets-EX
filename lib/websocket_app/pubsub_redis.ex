defmodule WebsocketApp.PubSubRedis do
  @moduledoc """
  Redis-based PubSub adapter for distributing messages across clustered nodes.
  This allows WebSocket messages to be delivered to the correct node
  regardless of which node the client is connected to.
  """

  alias Phoenix.PubSub.Redis

  def start_link(_opts) do

    redis_host = System.get_env("REDIS_HOST", "redis")
    redis_port = String.to_integer(System.get_env("REDIS_PORT", "6379"))
    redis_password = System.get_env("REDIS_PASSWORD")
    redis_database = String.to_integer(System.get_env("REDIS_DATABASE", "0"))


    redis_options = [
      host: redis_host,
      port: redis_port,
      database: redis_database
    ]


    redis_options = if redis_password, do: Keyword.put(redis_options, :password, redis_password), else: redis_options


    config = [
      name: WebsocketApp.PubSub,
      adapter: Redis,
      redis_name: :pubsub_redis,
      node_name: node(),
      redis: redis_options
    ]

    Redis.start_link(config)
  end
end
