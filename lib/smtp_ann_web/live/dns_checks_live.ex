defmodule SmtpAnnWeb.DnsChecksLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.DnsRecords

  def lookup_error(assigns) do
    ~H"""
    DNS Lookup Error Occured
    """
  end

  def no_results(assigns) do
    ~H"""
    No results were found for that record type
    """
  end

  attr :parsed, :map, required: true
  attr :header, :string, required: true
  attr :key, :atom, required: true

  def entry_group(assigns) do
    ~H"""
    <div :if={@parsed[@key]}>
      <h3 class="font-semibold"><%= @header %></h3>
      <div class="grid grid-cols-3 gap-2">
        <p :for={item <- @parsed[@key]}><%= to_string(item) %></p>
      </div>
    </div>
    """
  end

  attr :record, :map, required: true

  def record(%{record: %{type: :mx, error: nil}} = assigns) do
    assigns = assign_new(assigns, :parsed, fn -> assigns[:record].parsed end)
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">MX Entry</h2>
        <p> Server: <%= @parsed.server %>, Priority: <%= @parsed.priority %> </p>
        <p> TTL: <%= @record.ttl %> </p>
      </div>
    </div>
    """
  end

  def record(%{record: %{type: :ns, error: nil}} = assigns) do
    assigns = assign_new(assigns, :parsed, fn -> assigns[:record].parsed end)
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">NS Entry</h2>
        <p> Server: <%= @parsed.server %></p>
        <p> TTL: <%= @record.ttl %> </p>
      </div>
    </div>
    """
  end

  def record(%{record: %{type: :spf, error: nil}} = assigns) do
    assigns = assign_new(assigns, :parsed, fn -> assigns[:record].parsed end)
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">SPF Entry</h2>
        <h3 class="font-semibold">SPF Record</h3>
        <p><%= @record.data %></p>
        <.entry_group parsed={@parsed} key={:ip4_entry} header="Allowed Sending IPs" />
        <.entry_group
          parsed={@parsed}
          key={:include_entry}
          header="Include SPF Records from Domains"
        />
        <.entry_group
          parsed={@parsed}
          key={:a_entry}
          header="Allow Sending for A Records in Domains"
        />
        <.entry_group parsed={@parsed} key={:exists_entry} header="Records to match" />
        <.entry_group parsed={@parsed} key={:ptr_entry} header="Allowed PTR records" />
        <.entry_group parsed={@parsed} key={:mx_entry} header="Allowed mx records" />
      </div>
    </div>
    """
  end

  def record(%{record: %{type: :spf, error: {:parse_error, _}}} = assigns) do
    assigns =
      assigns
      |> assign_new(:error_type, fn -> DnsRecords.extract_error_type(assigns[:record]) end)
      |> assign_new(:error_pos, fn -> DnsRecords.extract_error_pos(assigns[:record]) end)
      |> assign_new(:unparsed, fn -> DnsRecords.extract_unparsed(assigns[:record]) end)

    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">SPF Record Parse with Error</h2>
        <h3 class="font-semibold">SPF Record</h3>
        <p><%= @record.data %></p>
        <h3 class="font-semibold">Error Summary</h3>
        <p>
          Parsing error (<%= @error_type %>) at <%= @error_pos + 1 %>, check the formatting of the SPF record
        </p>
        <h3 class="font-semibold">Succesfully Parsed Sections</h3>
        <.entry_group parsed={@record.parsed} key={:ip4_entry} header="Allowed Sending IPs" />
        <.entry_group
          parsed={@record.parsed}
          key={:include_entry}
          header="Include SPF Records from Domains"
        />
        <.entry_group
          parsed={@record.parsed}
          key={:a_entry}
          header="Allow Sending for A Records in Domains"
        />
        <.entry_group parsed={@record.parsed} key={:exists_entry} header="Records to match" />
        <.entry_group parsed={@record.parsed} key={:ptr_entry} header="Allowed PTR records" />
        <.entry_group parsed={@record.parsed} key={:mx_entry} header="Allowed mx records" />
      </div>
    </div>
    """
  end

  def record(assigns) do
    ~H"""
    <p>
      <%= inspect(@record) %>
    </p>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="my-32 mx-32">
      <div class="w-1/2">
        <.form for={@lookup_form} phx-submit="lookup-submitted">
          <div class="flex flex-row">
              <.input label="Target Domain" field={@lookup_form[:domain_name]} />
              <.input
                type="select"
                options={DnsRecords.record_types()}
                field={@lookup_form[:record_type]}
                class="mt-5"
              />
          </div>
          <.button class="btn-primary">Submit</.button>
        </.form>
      </div>
      <div :if={@result}>
        <%= case @result do %>
          <% {:error, :lookup_error} -> %>
            <.lookup_error />
          <% {:ok, []} -> %>
            <.no_results />
          <% {:ok, records} -> %>
            <div class="flex flex-col gap-3">
            <.record :for={record <- records} record={record} />
            </div>
        <% end %>
      </div>
    </div>
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
