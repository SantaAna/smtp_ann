defmodule SmtpAnn.DnsblServersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SmtpAnn.DnsblServers` context.
  """

  @doc """
  Generate a dnsbl_server.
  """
  def dnsbl_server_fixture(attrs \\ %{}) do
    {:ok, dnsbl_server} =
      attrs
      |> Enum.into(%{
        dns_name: "some dns_name"
      })
      |> SmtpAnn.DnsblServers.create_dnsbl_server()

    dnsbl_server
  end
end
