defmodule SmtpAnn.Dnsbl do
  require Logger
  @moduledoc """
  Functions for looking up entries in 
  [DNS based blacklists](https://en.wikipedia.org/wiki/Domain_Name_System_blocklist)
  """

  @type ipaddress :: String.t()
  @type bldomain :: String.t()

  @doc """
  Using the blacklist domain provided will look up the 
  ip address.  

  {:ok, :ok} indicates that the check ran and the ip was not found in any blacklist.
  {:ok, :black_listed} indicates that the check ran and the ip was found on the blacklist
  {:error, string} indicates that the test was not run due to an error.
  """
  @spec lookup_ipv4(bldomain, ipaddress) :: {:ok, term} | {:error, String.t()}
  def lookup_ipv4(bldomain, ipaddress) do
    with true <- valid_ipv4_string?(ipaddress),
         lookup <- "#{reverse_octets(ipaddress)}.#{bldomain}" do
      case :inet_res.resolve(String.to_charlist(lookup), :in, :a) do
        {:error, :nxdomain} -> {:ok, :ok}
        _ -> 
          {:ok, :black_listed}
          Logger.info([black_list_response: "#{inspect lookup}", bl_server: bldomain])
      end
    else
      _ -> {:error, "invalid IP address"}
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
