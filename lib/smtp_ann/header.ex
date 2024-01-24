defmodule SmtpAnn.Header do
  alias SmtpAnn.ExecuteIf
  require SmtpAnn.ExecuteIf

  @doc """
  Parses a header into a map with string 
  keys reprsenting header tags.

  Each key contains a list of values that 
  were provided for that tag in the header.
  """
  @spec parse(header :: String.t()) :: {:error, String.t()} | {:ok, map}
  def parse(header) when is_binary(header) do
    wrap(header)
    |> applicative(&unfold/1)
    |> applicative(&entry_split/1)
    |> IO.inspect(lable: "should be lines")
    |> applicative(&has_label_format/1)
    |> applicative(&has_enough_entries?/1)
    |> applicative(&entry_label/1)
    |> applicative(&has_receive_headers?/1)
    |> applicative(fn labels ->
      rec = Enum.map(labels["Received"], &parse_received/1)
      Map.put(labels, "Received", rec)
    end)
    |> applicative(fn labels ->
      Map.put(labels, "Received", delay_added(labels))
    end)
    |> applicative(fn labels ->
      Map.put(labels, "delivery_time", total_delivery_time(labels))
    end)
    |> applicative(fn
      %{"Received-SPF" => spf_headers} = input ->
        rec = Enum.map(spf_headers, &parse_spf/1)
        Map.put(input, "Received-SPF", rec)
    end)
  end

  @spec wrap(term) :: {:ok, term}
  def wrap(value), do: {:ok, value}

  def wrap_if(value) do
    case value do
      {:ok, _} -> value
      {:error, _} -> value
      _ -> {:ok, value}
    end
  end

  @spec applicative(term, (term -> term)) :: {:ok, term} | {:error, term}
  def applicative(value, fun) do
    case value do
      {:ok, unwrapped} ->
        wrap_if(fun.(unwrapped))

      {:error, _} ->
        IO.inspect(value, label: "rejected value")
    end
  end

  def total_delivery_time(%{"Received" => r}) do
    r
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, entry} ->
      case entry["delay_added"] do
        nil -> 0
        n when n < 0 -> 0
        n -> n
      end
    end)
    |> Enum.sum()
  end

  def delay_added(%{"Received" => r}) do
    with_delay =
      r
      |> Enum.with_index()
      |> Enum.filter(&match?({{:ok, _}, _}, &1))
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [{{:ok, f}, ind}, {{:ok, s}, _}] ->
        {ind, {:ok, Map.put(f, "delay_added", DateTime.diff(s["date"], f["date"]))}}
      end)

    Enum.reduce(with_delay, r, fn {ind, value}, acc ->
      List.replace_at(acc, ind, value)
    end)
  end

  def has_enough_entries?(entries) when is_list(entries) and length(entries) > 1 do
    entries
  end

  def has_enough_entries?(_),
    do: {:error, "invalid header string, does not appear to contain headers"}

  def has_receive_headers?(%{"Received" => received} = map) when is_list(received) do
    map
  end

  def has_receive_headers?(_), do: {:error, "missing received headers"}

  def has_label_format(lines) do
    if Enum.all?(lines, &String.contains?(&1, ":")) do
      {:ok, lines}
    else
      {:error,
        """
        Input is not composed of valid header tags.
        Tags should be in a <tag name>:<tag-value> 
        format.
        """
      }
    end
  end 

  @doc """
  Headers are usually presented to a user "folded",
  spreading single header entries over multiple lines
  starting with a whitespace character

  This function takes a folded header and replaces the 
  folds with whitespace characters.
  """
  @spec unfold(header :: String.t()) :: String.t()
  def unfold(header) when is_binary(header) do
    header |> String.replace(~r/\n+[[:blank:]]/, " ")
  end

  @doc """
  An unfolded header has entries that are separated by 
  new lines.
  """
  @spec entry_split(unfolded :: String.t()) :: list
  def entry_split(unfolded) when is_binary(unfolded) do
    unfolded |> String.split(~r/\n/, trim: true)
  end

  @doc """
  Creates a map with string keys that represents each 
  entry type as a key with a list of values.

  The list is prepended as the header is read so the 
  ordering of the values is reversed when compared to 
  what is in the header.  Since header sections are 
  prepended as the message goes between servers we 
  usually want the order reversed.
  """
  @spec entry_label(split :: list) :: map
  def entry_label(split) do
    split
    |> Enum.map(fn entry -> String.split(entry, ":", parts: 2) end)
    |> Enum.reduce(%{}, fn [label, entry], acc ->
      Map.update(acc, label, [entry], &[entry | &1])
    end)
  end

  def parse_spf(spf_string) when is_binary(spf_string) do
    %{
      error: false,
      argument: spf_string
    }
    |> ExecuteIf.match(match: %{error: false}, function: &extract_spf_info/1)
    |> ExecuteIf.match(match: %{error: false}, function: &{:ok, &1.result})
    |> ExecuteIf.match(match: %{error: true}, function: &{:error, &1.reason, &1.argument})
  end

  def extract_spf_info(%{argument: spf_string} = input) do
    case Regex.named_captures(
           ~r/^(?<result>[[:alnum:]]+) \((?<spf_result>[[:print:]]+)\) receiver=(?<receiver>[[:print:]]+); client-ip=(?<sender>[[:print:]]+).*/,
           String.trim(spf_string)
         ) do
      nil ->
        input |> Map.put(:error, true) |> Map.put(:reason, "invalid spf string")

      map ->
        input |> Map.put(:result, map)
    end
  end

  def parse_received(received_string) when is_binary(received_string) do
    %{
      error: false,
      argument: received_string
    }
    |> ExecuteIf.match(match: %{error: false}, function: &extract_info/1)
    |> ExecuteIf.match(match: %{error: false}, function: &date_to_parts/1)
    |> ExecuteIf.match(match: %{error: false}, function: &date_parts_to_datetime/1)
    |> ExecuteIf.match(match: %{error: false}, function: &{:ok, &1.transformed})
    |> ExecuteIf.match(match: %{error: true}, function: &{:error, &1.reason, &1.argument})
  end

  def extract_info(%{argument: received_string} = input) do
    case Regex.named_captures(
           ~r/from (?<sending_server>.*)?\w?by (?<receiving_server>.*) with (?<protocol>.*); (?<date>.*)/,
           received_string
         ) do
      nil -> Map.put(input, :error, true) |> Map.put(:reason, "invalid received string")
      match_map -> Map.put(input, :transformed, match_map)
    end
  end

  def date_to_parts(%{transformed: transformed} = input) do
    case extract_date_components(transformed["date"]) do
      nil ->
        Map.put(input, :error, true) |> Map.put(:reason, "invalid date time string")

      date_map ->
        put_in(input, [:transformed, "date"], date_map)
    end
  end

  def date_parts_to_datetime(%{transformed: transformed} = input) do
    case to_datetime(transformed["date"]) do
      {:error, _} ->
        Map.put(input, :error, true) |> Map.put(:reason, "could not parse to datetime")

      {:ok, dt} ->
        put_in(input, [:transformed, "date"], dt)
    end
  end

  def update_received_datetimes(%{"Received" => []} = header), do: header

  def update_received_datetimes(%{"Received" => received} = header) when is_list(received) do
    received
    |> Enum.flat_map(fn
      nil ->
        []

      rec ->
        case smtp_date_to_datetime(rec["date"]) do
          {:ok, date} ->
            [Map.put(rec, "date", date)]

          {:error, _} ->
            [Map.put(rec, "date", nil)]
        end
    end)
    |> then(&Map.put(header, "Received", &1))
  end

  @spec smtp_date_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def smtp_date_to_datetime(nil), do: {:error, "date missing"}

  def smtp_date_to_datetime(date_string) do
    date_string
    |> extract_date_components()
    |> to_datetime()
  end

  @spec extract_date_components(String.t()) :: map | nil
  def extract_date_components(date_string) when is_binary(date_string) do
    Regex.named_captures(
      ~r/(?<weekday>[[:alnum:]]{3}), (?<day>[[:digit:]]{1,2}) (?<month>[[:alnum:]]{3}) (?<year>[[:digit:]]{4}) (?<hour>[[:digit:]]{2}):(?<minute>[[:digit:]]{2}):(?<second>[[:digit:]]{2}) (?<offset>[+-]{1}[[:digit:]]{4})/,
      date_string
    )
  end

  @spec to_datetime(map) :: {:ok, DateTime.t()} | {:error, String.t()}
  def to_datetime(nil), do: {:error, "invalid date string"}

  def to_datetime(%{
        "day" => day,
        "month" => month,
        "year" => year,
        "hour" => hour,
        "minute" => minute,
        "second" => second,
        "offset" => offset
      }) do
    {offset_hour, offset_minute} = String.split_at(offset, 3)
    day = if String.length(day) == 2, do: day, else: "0" <> day

    with {:ok, dt, _} <-
           DateTime.from_iso8601(
             "#{year}-#{convert_month(month)}-#{day}T#{hour}:#{minute}:#{second}#{offset_hour}:#{offset_minute}"
           ),
         do: {:ok, dt}
  end

  defp convert_month(three_letter_month) when is_binary(three_letter_month) do
    Map.get(
      %{
        "Jan" => "01",
        "Feb" => "02",
        "Mar" => "03",
        "Apr" => "04",
        "May" => "05",
        "Jun" => "06",
        "Jul" => "07",
        "Aug" => "08",
        "Sep" => "09",
        "Oct" => "10",
        "Nov" => "11",
        "Dec" => "12"
      },
      three_letter_month
    )
  end
end
