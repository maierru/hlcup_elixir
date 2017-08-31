defmodule HlcupWeb.PageController do
  use HlcupWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
