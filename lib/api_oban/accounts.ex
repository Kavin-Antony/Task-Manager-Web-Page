defmodule ApiOban.Accounts do
  use Ash.Domain, otp_app: :api_oban, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource ApiOban.Accounts.Token
    resource ApiOban.Accounts.User
  end
end
