defmodule ApiObanWeb.AshJsonApiRouter do
  use AshJsonApi.Router,
    domains: [ApiOban.Tasks],
    open_api: "/open_api"
end
