defmodule SmtpAnn.IpAddress do
  defstruct [:address, :prefix_length]

  def new(ip) when is_list(ip) do
    if length(ip) == 4 do
      %__MODULE__{
        address: ip
      }
    else
      {ip, [cidr]} = Enum.split(ip, 4)
      IO.inspect({ip, cidr})
      Enum.join(ip, ".") <> "/" <> to_string(cidr)

      %__MODULE__{
        address: ip,
        prefix_length: cidr
      }
    end
  end
end

defimpl String.Chars, for: SmtpAnn.IpAddress do
  def to_string(ip) do
    case ip do
      %{address: address, prefix_length: cidr} when is_number(cidr) ->
        Enum.join(address, ".") <> "/" <> "#{cidr}"

      %{address: address} when is_list(address) ->
        Enum.join(address, ".")

      _ ->
        "invalid"
    end
  end
end
