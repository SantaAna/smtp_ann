defmodule SmtpAnn.DnsblServers.DnsblServer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dnsblserver" do
    field :dns_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dnsbl_server, attrs) do
    dnsbl_server
    |> cast(attrs, [:dns_name])
    |> validate_required([:dns_name])
    |> validate_domain_name()
  end

  @doc """
  Quick and dirty check that a dns hostname is valid
  """
  def validate_domain_name(cs) do
    validate_change(cs, :dns_name, fn :dns_name, dns_name -> 
      if Regex.match?(~r/^([[:alnum:]-]+\.)+([[:alnum:]-]+\.?)$/, dns_name) do
        [] 
        else
        [dns_name: "invalid dns name format"]
      end
    end)
  end
end
