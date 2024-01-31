defmodule SmtpAnn.DnsRecords.DnsRecord do
  alias SmtpAnn.SpfParser

  @spec resolve_mx(String.t()) :: {:error, String.t()} | {:ok, list}
  def resolve_mx(domain_name) when is_binary(domain_name) do
    with {:ok, resp} <- :inet_res.resolve(String.to_charlist(domain_name), :in, :mx, [], 4_000) do
      apply(:inet_dns, :inet_dns.record_type(resp), [resp])[:anlist]
      |> Enum.map(&:inet_dns.rr/1)
      |> Enum.map(&parse_mx_response/1)
      |> then(&{:ok, &1})
    end
  end

  @spec resolve_ns(String.t()) :: {:error, String.t()} | {:ok, list}
  def resolve_ns(domain_name) when is_binary(domain_name) do
    with {:ok, resp} <- :inet_res.resolve(String.to_charlist(domain_name), :in, :ns, [], 4_000) do
      apply(:inet_dns, :inet_dns.record_type(resp), [resp])[:anlist]
      |> Enum.map(&:inet_dns.rr/1)
      |> Enum.map(&parse_ns_response/1)
      |> then(&{:ok, &1})
    end
  end

  @spec resolve_spf(String.t()) :: {:error, String.t()} | {:ok, list}
  def resolve_spf(domain_name) when is_binary(domain_name) do
    with {:ok, resp} <- :inet_res.resolve(String.to_charlist(domain_name), :in, :txt, [], 4_000) do
      apply(:inet_dns, :inet_dns.record_type(resp), [resp])[:anlist]
      |> Enum.map(&:inet_dns.rr/1)
      |> Enum.filter(&is_spf_record?/1)
      |> Enum.map(&parse_spf_response/1)
      |> Enum.map(&parse_spf_record/1)
      |> then(&{:ok, &1})
    end
  end
  
  @doc """
  Takes a parsed SPF record response 
  and attempts to parse the SPF text 
  data.  
  """
  def parse_spf_record(%{data: spf_data} = spf_record) do
    case SpfParser.spf(spf_data) do
      {:error, reason, unparsed_reaminder, _, _, _} -> 
        Map.put(spf_record, :parse_error, reason)
        |> Map.put(:unparsed, unparsed_reaminder)
      {:ok, parsed, _, _, _, _} ->
        Map.put(spf_record, :parsed, parsed)
    end
  end

  def parse_spf_response(erl_rr) when is_list(erl_rr) do
    data =
      if is_list(erl_rr[:data]) do
        erl_rr[:data]
        |> Enum.map(&to_string/1)
        |> Enum.join("")
      else
        to_string(erl_rr[:data])
      end

    %{
      ttl: erl_rr[:ttl],
      type: :spf,
      data: data
    }
  end

  def parse_ns_response(erl_rr) when is_list(erl_rr) do
    %{
      type: :ns,
      ttl: erl_rr[:ttl],
      server: to_string(erl_rr[:data])
    }
  end

  def parse_mx_response(erl_rr) when is_list(erl_rr) do
    %{
      type: :mx,
      ttl: erl_rr[:ttl],
      priority: elem(erl_rr[:data], 0),
      server: to_string(elem(erl_rr[:data], 1))
    }
  end

  def is_spf_record?(dns_rr) do
    dns_rr[:data]
    |> List.first()
    |> to_string()
    |> String.starts_with?("v=spf1")
  end
end
