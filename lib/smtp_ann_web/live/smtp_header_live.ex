defmodule SmtpAnnWeb.SmtpHeaderLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.Header

  attr :entry, :any, required: true

  def received_line(assigns) do
    ~H"""
    <div>
      <%= case @entry do %>
        <% {:ok, entry} -> %>
          <p>Sent From: <%= entry["sending_server"] %></p>
          <p>Sent To: <%= entry["receiving_server"] %></p>
          <p>Received at: <%= entry["date"] %></p>
          <p>Protocol: <%= entry["protocol"] %></p>
          <p>Delay Added: <%= entry["delay_added"] || "*" %> </p> 
        <% {:error, reason, string} -> %>
          <p>Couldn't parse due to: <%= reason %></p>
          <p>Full Entry: <%= string %></p>
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
    <div class="flex flex-row"> 
      <p :if={@entry["result"] == "Pass"} class="text-green-500 text-lg mr-2">
        Pass
      </p>
      <p :if={@entry["result"] != "Pass"} class="text-red-500 text-lg mr-2">
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
      Total Delivery Time: <%= @delivery_time %>
    </p>
    """
  end

  attr :subject, :string, required: true
  def subject(assigns) do
    ~H"""
    <p>
      Subject: <%= @subject %>
    </p>
    """
  end

  def render(assigns) do
    ~H"""
    <form phx-submit="header-submitted">
      <.input type="textarea" name="header" value="" />
      <.button>Submit</.button>
      <div :if={@error_message}>
        <h2 class="text-red-500 text-xl">
          Error: <%= @error_message %>
        </h2>
      </div>
      <div :if={@parsed_header} class="mt-5 flex flex-col gap-3">
        <.delivery_time delivery_time={@parsed_header["delivery_time"]} />
        <.subject subject={@parsed_header["Subject"]} /> 
        <.to_from_entry email_to={@parsed_header["To"]} direction="To" />
        <.to_from_entry email_to={@parsed_header["From"]} direction="From" />
        <.spf_entry :for={{:ok, spf_entry} <- @parsed_header["Received-SPF"]} entry={spf_entry}/>
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
