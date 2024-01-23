defmodule SmtpAnn.Repo do
  use Ecto.Repo,
    otp_app: :smtp_ann,
    adapter: Ecto.Adapters.Postgres
end
