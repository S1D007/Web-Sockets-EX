defmodule WebsocketAppWeb.PageController do
  use WebsocketAppWeb, :controller

  def home(conn, _params) do


    render(conn, :home, layout: false)
  end
end
