# Multi-stage build for Elixir Phoenix application
FROM hexpm/elixir:1.14.5-erlang-25.3.2-debian-bullseye-20230227-slim as build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git npm nodejs \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set environment variables
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory and copy the Elixir project into it
WORKDIR /app
COPY mix.exs mix.lock ./
COPY config config
COPY priv priv

# Install mix dependencies
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Copy assets
COPY assets assets

# Compile assets
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# Compile the release
COPY lib lib
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Build the release
RUN mix release

# Start a new build stage for the final image
FROM debian:bullseye-slim AS app

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG en_US.utf8
ENV MIX_ENV=prod
ENV PHX_SERVER=true

WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/websocket_app ./

# Create a non-root user and change ownership
RUN useradd -m app
RUN chown -R app: /app
USER app

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:4000/health/liveness || exit 1

# Expose port 4000
EXPOSE 4000

# Set the default command to start the Phoenix server
CMD ["/app/bin/server"]