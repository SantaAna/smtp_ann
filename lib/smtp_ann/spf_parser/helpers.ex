defmodule SmtpAnn.SpfParser.Helpers do
  import NimbleParsec

  def prefix do
    ignore(string("v=spf1"))
  end

  def oct do
    integer(min: 1, max: 3)
    |> ignore(times(string("."), max: 1))
  end

  def cidr_suffix do
    ignore(ascii_char([?/]))
    |> integer(min: 1, max: 2)
  end

  def ip4_address do
    times(oct(), 4)
    |> optional(cidr_suffix())
    |> tag(:ip_address)
  end

  def domain_name_component do
    ascii_char([?a..?z, ?A..?Z, ?_])
    |> times(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?-]), max: 66)
  end

  def domain_name do
    domain_name_component()
    |> times(concat(ascii_char([?.]), domain_name_component()), max: 126)
    |> ignore(times(ascii_char([?.]), max: 1))
    |> tag(:domain_name)
  end

  def label(label) do
    ignore(string(label))
    |> ignore(times(ascii_char([?:]), max: 1))
  end

  def include_entry do
    label("include")
    |> times(domain_name(), 1)
    |> tag(:include_entry)
  end

  def exists_entry do
    label("exists")
    |> times(domain_name(), 1)
    |> tag(:exists_entry)
  end

  def ptr_entry do
    label("ptr")
    |> times(domain_name(), max: 1)
    |> tag(:ptr_entry)
  end

  def mx_entry do
    label("mx")
    |> times(choice([concat(domain_name(), cidr_suffix()), domain_name(), cidr_suffix()]), max: 1)
    |> tag(:mx_entry)
  end

  def a_entry do
    ignore(ascii_char([?a]))
    |> ignore(times(ascii_char([?:]), max: 1))
    |> times(
      choice([concat(domain_name(), cidr_suffix()), domain_name(), cidr_suffix()]),
      max: 1
    )
    |> tag(:a_entry)
  end

  def ip4_entry do
    ignore(string("ip4:"))
    |> times(ip4_address(), 1)
    |> tag(:ip4_entry)
  end

  def all_entry do
    ascii_char([?+, ?-])
    |> string("all")
    |> tag(:all_entry)
  end
  
  def detect_leftover(rest, args, context, _line, offset) do
    if rest != "" do
      {:error, %{type: :invalid_label, pos: offset}}
    else
      {rest, args, Map.put(context, :hello, "there")}
    end
  end

  def spf do
    prefix()
    |> repeat(
      concat(
        ignore(string(" ")),
        choice([
          include_entry(),
          exists_entry(),
          ptr_entry(),
          mx_entry(),
          a_entry(),
          ip4_entry()
        ])
      )
    )
    |> optional((concat(ignore(string(" ")), all_entry())))
    |> post_traverse({:detect_leftover, []})
  end
end
