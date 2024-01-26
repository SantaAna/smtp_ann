defmodule SmtpAnnWeb.SmtpHeaderLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.Header

  attr :entry, :any, required: true

  def received_line(assigns) do
    ~H"""
    <div>
      <%= case @entry do %>
        <% {:ok, entry} -> %>
          <div tabindex="0" class="collapse collapse-arrow border border-base-300 bg-base-200">
            <div class="collapse-title text-xl font-medium">
              <%= entry["sending_server"] %>
            </div>
            <div class="collapse-content">
              <p>Sent From: <%= entry["sending_server"] %></p>
              <p>Sent To: <%= entry["receiving_server"] %></p>
              <p>Received at: <%= entry["date"] %></p>
              <p>Protocol: <%= entry["protocol"] %></p>
              <p>Delay Added: <%= entry["delay_added"] || "*" %></p>
            </div>
          </div>
        <% {:error, reason, string} -> %>
          <div tabindex="0" class="collapse collapse-arrow border border-base-300 bg-base-200">
            <div class="collapse-title text-xl font-medium">
              <p>Couldn't parse due to: <%= reason %></p>
            </div>
            <div class="collapse-content">
              <p>Full Entry: <%= string %></p>
            </div>
          </div>
      <% end %>
    </div>
    """
  end

  attr :email_to, :list, required: true
  attr :direction, :string, required: true

  def to_from_entry(assigns) do
    ~H"""
    <div class="flex flex-row">
      <h2 class="mr-2"><%= @direction %>:</h2>
      <span><%= Enum.join(@email_to, ",") %></span>
    </div>
    """
  end

  attr :entry, :map, required: true

  def spf_entry(assigns) do
    ~H"""
    <div class="flex flex-row gap-2">
      <p :if={@entry["result"] == "Pass"} class="text-success">
        Pass
      </p>
      <p :if={@entry["result"] != "Pass"} class="text-error">
        Fail
      </p>
      <p>
        Sender: <%= @entry["sender"] %>
      </p>
    </div>
    """
  end

  attr :delivery_time, :integer, required: true

  def delivery_time(assigns) do
    ~H"""
    <p>
      Time to Delivery: <%= @delivery_time %> seconds
    </p>
    """
  end

  attr :subject, :string, required: true

  def subject(assigns) do
    ~H"""
    <p>
      <span class="font-bold">Subject</span>: <%= @subject %>
    </p>
    """
  end

  attr :subject, :string, required: true
  attr :from, :string, required: true
  attr :to, :string, required: true
  attr :delivery_time, :integer, required: true

  def summary(assigns) do
    ~H"""
    <table class="table">
      <tbody>
        <tr>
          <th class="font-bold ">Subject</th>
          <td><%= @subject %></td>
        </tr>
        <tr></tr>
        <th class="font-bold ">From</th>
        <td><%= Enum.join(@from, ",") %></td>
        <tr>
          <th class="font-bold ">To</th>
          <td><%= Enum.join(@to, ",") %></td>
        </tr>
        <tr>
          <th class="font-bold ">Time to Deliver</th>
          <td><%= @delivery_time %> seconds</td>
        </tr>
      </tbody>
    </table>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="my-10 mx-10">
      <.form phx-submit="header-submitted" for={@header_form}>
        <div class="form-control">
          <.input
            phx-hook="ClearValue"
            type="textarea"
            field={@header_form[:header]}
            id="header-input"
            class="textarea-lg w-full textarea-bordered h-48" label="Paste SMTP Header Below" />
        </div>
        <div class="flex flex-row mt-3 gap-3">
          <.button class="btn-primary">Submit</.button>
          <.button
            type="button"
            class="btn-secondary"
            phx-click={JS.push("clear-input") |> JS.dispatch("clear-value", to: "#header-input")}
          >
            Clear
          </.button>
        </div>
        <div :if={@parsed_header} class="mt-5 flex flex-col gap-3">
          <h2 class="text-xl font-bold mt-5 mb-2">Summary</h2>
          <.summary
            from={@parsed_header["From"]}
            to={@parsed_header["To"]}
            subject={@parsed_header["Subject"]}
            delivery_time={@parsed_header["delivery_time"]}
          />
          <h2 class="text-xl font-bold mt-5 mb-2">SPF Results</h2>
          <.spf_entry :for={{:ok, spf_entry} <- @parsed_header["Received-SPF"]} entry={spf_entry} />
          <h2 class="text-xl font-bold mt-5 mb-2">Hops</h2>
          <.received_line :for={entry <- @parsed_header["Received"]} entry={entry} />
        </div>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    header_form = to_form(Header.header_cs(), as: "header_form")
    socket
    |> assign(header_form: header_form)
    |> assign(parsed_header: nil)
    |> then(&{:ok, &1})
  end

  def handle_event("clear-input", _params, socket) do
    socket
    |> assign(header_form: to_form(Header.header_cs(), as: "header_form"))
    |> assign(parsed_header: nil)
    |> then(&{:noreply, &1})
  end

  def handle_event("header-submitted", %{"header_form" => params}, socket) do
    
    case Header.validate_header(params) do
      {:ok, validated} -> 
        socket
        |> assign(parsed_header: validated.parsed)
        |> then(&{:noreply, &1})
      {:error, cs} ->
        socket
        |> assign(header_form: to_form(cs, as: "header_form"))
        |> then(&{:noreply, &1})
    end
  end
end
