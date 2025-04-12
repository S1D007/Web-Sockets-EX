# WebSocket App

A real-time web application built with Phoenix Framework that demonstrates WebSocket functionality.

## Features

- Real-time bidirectional communication using WebSockets
- Built with Phoenix LiveView
- Uses Bandit as the web server
- PostgreSQL database integration

## Prerequisites

Before you begin, ensure you have the following installed:
- Elixir (~> 1.14)
- Phoenix Framework
- PostgreSQL
- Node.js (for asset compilation)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/S1D007/Web-Sockets-EX
cd Web-Sockets-EX
```

2. Install dependencies:
```bash
mix deps.get
mix deps.compile
```

3. Setup the database:
```bash
mix ecto.setup
```

4. Install and build assets:
```bash
mix assets.setup
mix assets.build
```

## Running the Application

To start your Phoenix server:

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Development

- Run tests: `mix test`
- Run interactive Elixir shell: `iex -S mix`
- Run interactive Phoenix server: `iex -S mix phx.server`

## Configuration

The application can be configured through the following files:
- `config/config.exs` - Main configuration
- `config/dev.exs` - Development environment
- `config/test.exs` - Test environment
- `config/runtime.exs` - Runtime configuration
- `config/prod.exs` - Production environment

## Project Structure

```
lib/
├── websocket_app/ - Core application logic
└── websocket_app_web/ - Web-related code (controllers, views, templates)
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Bandit Web Server](https://github.com/mtrudel/bandit)
- [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)
