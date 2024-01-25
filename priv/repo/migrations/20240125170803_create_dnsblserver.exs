defmodule SmtpAnn.Repo.Migrations.CreateDnsblserver do
  use Ecto.Migration

  def change do
    create table(:dnsblserver) do
      add :dns_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
