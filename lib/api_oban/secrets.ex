defmodule ApiOban.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        ApiOban.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:api_oban, :token_signing_secret)
  end
end
