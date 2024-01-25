defmodule SmtpAnn.DnsblServers do
  @moduledoc """
  The DnsblServers context.
  """

  import Ecto.Query, warn: false
  alias SmtpAnn.Repo

  alias SmtpAnn.DnsblServers.DnsblServer

  @doc """
  Returns the list of dnsblserver.

  ## Examples

      iex> list_dnsblserver()
      [%DnsblServer{}, ...]

  """
  def list_dnsblserver do
    Repo.all(DnsblServer)
  end

  @doc """
  Gets a single dnsbl_server.

  Raises `Ecto.NoResultsError` if the Dnsbl server does not exist.

  ## Examples

      iex> get_dnsbl_server!(123)
      %DnsblServer{}

      iex> get_dnsbl_server!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dnsbl_server!(id), do: Repo.get!(DnsblServer, id)

  @doc """
  Creates a dnsbl_server.

  ## Examples

      iex> create_dnsbl_server(%{field: value})
      {:ok, %DnsblServer{}}

      iex> create_dnsbl_server(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dnsbl_server(attrs \\ %{}) do
    %DnsblServer{}
    |> DnsblServer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a dnsbl_server.

  ## Examples

      iex> update_dnsbl_server(dnsbl_server, %{field: new_value})
      {:ok, %DnsblServer{}}

      iex> update_dnsbl_server(dnsbl_server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dnsbl_server(%DnsblServer{} = dnsbl_server, attrs) do
    dnsbl_server
    |> DnsblServer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dnsbl_server.

  ## Examples

      iex> delete_dnsbl_server(dnsbl_server)
      {:ok, %DnsblServer{}}

      iex> delete_dnsbl_server(dnsbl_server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dnsbl_server(%DnsblServer{} = dnsbl_server) do
    Repo.delete(dnsbl_server)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dnsbl_server changes.

  ## Examples

      iex> change_dnsbl_server(dnsbl_server)
      %Ecto.Changeset{data: %DnsblServer{}}

  """
  def change_dnsbl_server(%DnsblServer{} = dnsbl_server, attrs \\ %{}) do
    DnsblServer.changeset(dnsbl_server, attrs)
  end
end
