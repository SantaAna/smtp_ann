defmodule SmtpAnnWeb.DnsChecksLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.DnsRecords


  def render(assigns) do
    ~H"""
      <div class="w-1/2">
      <.form for={@lookup_form} phx-submit="lookup-submitted">
        <.input label="Target Domain" field={@lookup_form[:domain_name]}/>
        <.input type="select" options={DnsRecords.record_types()} field={@lookup_form[:record_type]}>
        </.input>
        <.button class="btn-primary"> Submit </.button>
      </.form>
      </div>
      <%= inspect(@result) %>
    """
  end

  def mount(_parmas, _session, socket) do
    lookup_form = to_form(DnsRecords.dns_lookup_changeset(), as: "lookup_form")
    socket
    |> assign(:lookup_form, lookup_form)
    |> assign(:result, nil)
    |> then(&{:ok, &1})
  end

  def handle_event("lookup-submitted", %{"lookup_form" => params}, socket) do
    case DnsRecords.lookup_record(params) do
      {:error, cs} ->  
        socket
        |> assign(:lookup_form, to_form(cs, as: "lookup_form"))
        |> then(&{:noreply, &1})
      result ->
        socket
        |> assign(:lookup_form, to_form(DnsRecords.dns_lookup_changeset(), as: "lookup_form"))
        |> assign(:result, result)
        |> then(&{:noreply, &1})
    end
  end
  
end
