defmodule SmtpAnn.Headers do
  import SmtpAnn.Headers.Header
  alias Ecto.Changeset

  def header_cs(params \\ %{}) do
    {%{}, %{header: :string, parsed: :map}}
    |> Changeset.cast(params, [:header])
    |> Changeset.validate_required([:header])
    |> then(fn cs ->
      if cs.errors == [] do
        Changeset.get_field(cs, :header)
        |> parse()
        |> then(fn 
          {:error, reason} -> %{error: reason}
          {:ok, parsed} -> parsed end) |> then(&Changeset.cast(cs, %{parsed: &1}, [:parsed]))
      else
        cs
      end
    end)
    |> Changeset.validate_change(:parsed, fn :parsed, parsed ->
      case parsed do
        %{error: message} ->
          [header: message]

        _ ->
          []
      end
    end)
    |> Changeset.prepare_changes(fn cs ->
      {:ok, parsed} = Changeset.get_change(cs, :parsed)
      Changeset.put_change(cs, :parsed, parsed)
    end)
  end

  def validate_header(params) do
    header_cs(params)
    |> Changeset.apply_action(:insert)
  end
end
