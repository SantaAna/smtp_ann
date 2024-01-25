defmodule SmtpAnnWeb.DnsblCheckLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.Dnsbl

  def render(assigns) do
    ~H"""
    <div class="my-3 mx-auto">
      <form phx-submit="ip-submitted">
        <div class="flex flex-row justify-center">
          <div class="flex flex-col gap-2">
            <div class="label">
              <div class="label-text text-lg">Enter IPv4 Address Here</div>
            </div>
            <input type="text" class="input input-bordered input-lg max-w-lg w-full" name="ipstring"/>
            <.button class="btn-primary flex-grow-0">Submit</.button>
          </div>
        </div>
      </form>
      <p :if={@error}>
       <%= @error %> 
      </p>
      <p :if={@result}>
       <%= @result %> 
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:ip_address, nil)
    |> assign(:error, nil) 
    |> assign(:result, nil)
    |> then(&{:ok, &1})
  end

  def handle_event("ip-submitted", %{"ipstring" => ipstring}, socket) do
    case Dnsbl.lookup_ipv4("dnsbl.sorbs.net", ipstring) do
        {:error, error_message} ->
          socket 
          |> assign(:error, error_message)
          |> assign(:result, nil)
          |> then(&{:noreply, &1})
        {:ok, :ok} -> 
          socket
          |> assign(:result, "Not Black Listed")
          |> assign(:error, nil)
          |> then(&{:noreply, &1})
        {:ok, :black_listed} ->
          socket
          |> assign(:result, "Black Listed")
          |> assign(:error, nil)
          |> then(&{:noreply, &1})
     end 
  end
end
