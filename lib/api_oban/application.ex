defmodule ApiOban.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ApiObanWeb.Telemetry,
      ApiOban.Repo,
      {DNSCluster, query: Application.get_env(:api_oban, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ApiOban.PubSub},
      # Start a worker by calling: ApiOban.Worker.start_link(arg)
      # {ApiOban.Worker, arg},
      # Start to serve requests, typically the last entry
      ApiObanWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiOban.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiObanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
