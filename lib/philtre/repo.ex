defmodule Philtre.Repo do
  use Ecto.Repo,
    otp_app: :philtre,
    adapter: Ecto.Adapters.Postgres
end
