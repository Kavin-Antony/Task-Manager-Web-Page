defmodule ApiOban.Tasks do
  use Ash.Domain,
    otp_app: :api_oban,
    extensions: [AshJsonApi.Domain]

  resources do
    resource ApiOban.Tasks.Task
  end
end
