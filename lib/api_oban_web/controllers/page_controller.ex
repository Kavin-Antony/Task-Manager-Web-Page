defmodule ApiObanWeb.PageController do
  use ApiObanWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
