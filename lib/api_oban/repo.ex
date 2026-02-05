defmodule ApiOban.Repo do
  use Ecto.Repo,
    otp_app: :api_oban,
    adapter: Ecto.Adapters.Postgres
end
