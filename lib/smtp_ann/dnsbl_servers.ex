defmodule SmtpAnn.DnsblServers do
  require Logger

  @moduledoc """
  The DnsblServers context.
  """

  import Ecto.Query, warn: false
  alias SmtpAnn.Repo
  alias Ecto.Changeset

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

  def ip_changeset(params \\ %{}) do
    {%{}, %{ip_address: :string}} 
    |> Changeset.cast(params, [:ip_address]) 
    |> Changeset.validate_required([:ip_address])
    |> Changeset.validate_change(:ip_address, fn :ip_address, ip_address -> 
      if valid_ipv4_string?(ip_address) do
        []
      else
        [ip_address: "invalid ip address string"]
      end
    end)
  end

  def validate_ip_input(params) when is_map(params) do
    ip_changeset(params)
    |> Changeset.apply_action(:insert)
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

  def validate_against_all(ip_address) do
    if valid_ipv4_string?(ip_address) do
      bl_list = list_dnsblserver()

      bl_list
      |> Enum.map(& &1.dns_name)
      |> Task.async_stream(fn name -> lookup_ipv4(name, ip_address) end)
      |> Enum.map(fn {:ok, res} -> res end)
      |> Enum.zip_with(bl_list, fn res, label -> {label.dns_name, res} end)
      |> Map.new()
    else
      {:error, "invalid ip string"}
    end
  end

  @type ipaddress :: String.t()
  @type bldomain :: String.t()
  @spec lookup_ipv4(bldomain, ipaddress) :: {:ok, term} | {:error, term}
  defp lookup_ipv4(bldomain, ipaddress) do
    lookup = "#{reverse_octets(ipaddress)}.#{bldomain}"

    case :inet_res.resolve(String.to_charlist(lookup), :in, :a, [], 4_000) do
      {:error, :nxdomain} ->
        {:ok, :ok}

      result when elem(result, 0) == :error ->
        {:error, result}

      _ ->
        Logger.info(black_list_response: "#{inspect(lookup)}", bl_server: bldomain)
        {:ok, :black_listed}
    end
  end

  defp valid_ipv4_string?(maybe_ip_string) when is_binary(maybe_ip_string) do
    with trimmed <- String.trim(maybe_ip_string),
         true <- Regex.match?(~r/(\d{1,3}\.){3}\d{1,3}$/, trimmed),
         string_octets <- String.split(maybe_ip_string, "."),
         parsed <- Enum.map(string_octets, &Integer.parse/1),
         true <- Enum.all?(parsed, &match?({_, _}, &1)),
         true <- Enum.all?(parsed, fn {num, _} -> num in 0..255 end) do
      true
    end
  end

  defp reverse_octets(ipaddress) do
    String.split(ipaddress, ".")
    |> Enum.reverse()
    |> Enum.join(".")
  end
end
