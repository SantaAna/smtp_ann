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
          <div class="collapse collapse-arrow border border-base-300 bg-base-200">
            <input type="checkbox" />
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
    <div class="flex flex-row gap-2">
      <div class="flex flex-col">
        <div class="font-bold ">Subject</div>
        <div class="font-bold ">From</div>
        <div class="font-bold ">To</div>
        <div class="font-bold ">Time to Deliver</div>
      </div>
      <div class="flex flex-col">
        <div><%= @subject %></div>
        <div><%= Enum.join(@from, ",") %></div>
        <div><%= Enum.join(@to, ",") %></div>
        <div><%= @delivery_time %> seconds</div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <form phx-submit="header-submitted">
      <div class="form-control">
        <div class="label">
          <div class="label-text">SMTP Header</div>
        </div>
        <.input
          phx-hook="ClearValue"
          type="textarea"
          name="header"
          value=""
          id="header-input"
          class="textarea-lg w-full textarea-bordered h-48"
        />
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
      <div :if={@error_message}>
        <h2 class="text-red-500 text-xl">
          Error: <%= @error_message %>
        </h2>
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
    </form>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(parsed_header: nil)
    |> assign(error_message: nil)
    |> then(&{:ok, &1})
  end

  def handle_event("clear-input", _params, socket) do
    socket
    |> assign(parsed_header: nil)
    |> then(&{:noreply, &1})
  end

  def handle_event("header-submitted", %{"header" => header}, socket) do
    {error_message, parsed_header} =
      case Header.parse(header) do
        {:ok, parsed_header} ->
          {nil, parsed_header}

        {:error, message} ->
          {message, nil}
      end

    socket
    |> assign(parsed_header: parsed_header)
    |> assign(error_message: error_message)
    |> then(&{:noreply, &1})
  end
end
