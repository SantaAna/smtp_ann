defmodule SmtpAnn.DnsblServersTest do
  use SmtpAnn.DataCase

  alias SmtpAnn.DnsblServers

  describe "dnsblserver" do
    alias SmtpAnn.DnsblServers.DnsblServer

    import SmtpAnn.DnsblServersFixtures

    @invalid_attrs %{dns_name: nil}

    test "list_dnsblserver/0 returns all dnsblserver" do
      dnsbl_server = dnsbl_server_fixture()
      assert DnsblServers.list_dnsblserver() == [dnsbl_server]
    end

    test "get_dnsbl_server!/1 returns the dnsbl_server with given id" do
      dnsbl_server = dnsbl_server_fixture()
      assert DnsblServers.get_dnsbl_server!(dnsbl_server.id) == dnsbl_server
    end

    test "create_dnsbl_server/1 with valid data creates a dnsbl_server" do
      valid_attrs = %{dns_name: "some dns_name"}

      assert {:ok, %DnsblServer{} = dnsbl_server} = DnsblServers.create_dnsbl_server(valid_attrs)
      assert dnsbl_server.dns_name == "some dns_name"
    end

    test "create_dnsbl_server/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DnsblServers.create_dnsbl_server(@invalid_attrs)
    end

    test "update_dnsbl_server/2 with valid data updates the dnsbl_server" do
      dnsbl_server = dnsbl_server_fixture()
      update_attrs = %{dns_name: "some updated dns_name"}

      assert {:ok, %DnsblServer{} = dnsbl_server} = DnsblServers.update_dnsbl_server(dnsbl_server, update_attrs)
      assert dnsbl_server.dns_name == "some updated dns_name"
    end

    test "update_dnsbl_server/2 with invalid data returns error changeset" do
      dnsbl_server = dnsbl_server_fixture()
      assert {:error, %Ecto.Changeset{}} = DnsblServers.update_dnsbl_server(dnsbl_server, @invalid_attrs)
      assert dnsbl_server == DnsblServers.get_dnsbl_server!(dnsbl_server.id)
    end

    test "delete_dnsbl_server/1 deletes the dnsbl_server" do
      dnsbl_server = dnsbl_server_fixture()
      assert {:ok, %DnsblServer{}} = DnsblServers.delete_dnsbl_server(dnsbl_server)
      assert_raise Ecto.NoResultsError, fn -> DnsblServers.get_dnsbl_server!(dnsbl_server.id) end
    end

    test "change_dnsbl_server/1 returns a dnsbl_server changeset" do
      dnsbl_server = dnsbl_server_fixture()
      assert %Ecto.Changeset{} = DnsblServers.change_dnsbl_server(dnsbl_server)
    end
  end
end
