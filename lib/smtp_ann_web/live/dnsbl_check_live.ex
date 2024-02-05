defmodule SmtpAnnWeb.DnsblCheckLive do
  use SmtpAnnWeb, :live_view
  alias SmtpAnn.DnsblServers
  alias Phoenix.LiveView.AsyncResult

  attr :source, :string, required: true
  attr :result, :atom, required: true

  def result(assigns) do
    ~H"""
    <div :if={@result == :blocked}>
      <div class="tooltip" data-tip={"blacklisted by #{@source}"}>
        <div class="badge badge-error p-2">
          <div class="flex flex-row gap-2">
            <.icon name="hero-exclamation-circle" />
            <p><%= @source %></p>
          </div>
        </div>
      </div>
    </div>
    <div :if={@result == :passed}>
      <div class="tooltip" data-tip={"not blacklisted by #{@source}"}>
        <div class="badge badge-success p-2">
          <div class="flex flex-row gap-2">
            <.icon name="hero-check-circle" />
            <p><%= @source %></p>
          </div>
        </div>
      </div>
    </div>
    <div :if={@result == :invalid}>
      <div class="tooltip" data-tip={"invalid response from #{@source}"}>
        <div class="badge badge-info p-2">
          <div class="flex flex-row gap-2">
            <.icon name="hero-question-mark-circle" />
            <p><%= @source %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :results, :list, required: true

  def result_grid(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 mt-5 mb-3">
      <h2 class="text-xl font-semibold text-center">Results</h2>
      <div class="grid grid-cols-4 gap-3">
        <.result :for={res <- @results} source={res.server} result={res.result} />
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="my-32 mx-auto">
      <.form phx-submit="ip-submitted" for={@ip_form}>
        <div class="flex flex-row justify-center">
          <div class="flex flex-col gap-2">
            <div class="label">
              <div class="label-text text-lg">Enter IPv4 Address Here</div>
            </div>
            <.input
              type="text"
              class="input input-bordered input-lg max-w-lg w-full"
              field={@ip_form[:ip_address]}
              label="IPv4 Address"
              disabled={if @result && @result.loading, do: true, else: nil}
            />
            <.button class={
              ["btn-primary", "flex-grow-0"] ++
                if @result && @result.loading, do: ["btn-disabled"], else: []
            }>
              Submit
            </.button>
          </div>
        </div>
      </.form>
      <p :if={@error} class="text-center">
        <%= @error %>
      </p>
      <%= if @result do %>
        <div :if={@result.loading} class="flex flex-row justify-center mt-5">
          <div class="flex flex-col gap-2">
            <span :if={@result.loading} class="loading loading-spinner loading-lg text-center"></span>
          </div>
        </div>
        <div :if={@result.ok? && @result.result} class="flex flex-row justify-center mt-10">
          <.result_grid results={@result.result} />
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    ip_form = to_form(DnsblServers.ip_changeset(), as: "ip_address")

    socket
    |> assign(:ip_address, nil)
    |> assign(:error, nil)
    |> assign(:result, nil)
    |> assign(:ip_form, ip_form)
    |> then(&{:ok, &1})
  end

  def handle_event("ip-submitted", %{"ip_address" => params}, socket) do
    case DnsblServers.validate_ip_input(params) do
      {:ok, %{ip_address: ip}} ->
        socket
        |> assign(:result, AsyncResult.loading())
        |> start_async(:fetch_bl, fn ->
          DnsblServers.validate_against_all(ip)
          |> Enum.map(fn
            {server, {:ok, :ok}} -> %{server: server, result: :passed}
            {server, {:ok, :blacklisted}} -> %{server: server, result: :failed}
            {server, {:error, _}} -> %{server: server, result: :invalid}
          end)
        end)
        |> assign(:ip_form, to_form(DnsblServers.ip_changeset(params), as: "ip_address"))
        |> then(&{:noreply, &1})

      {:error, cs} ->
        socket
        |> assign(:ip_form, to_form(cs, as: "ip_address"))
        |> then(&{:noreply, &1})
    end
  end

  def handle_async(:fetch_bl, {:ok, fetched_results}, socket) do
    %{result: result} = socket.assigns
    {:noreply, assign(socket, :result, AsyncResult.ok(result, fetched_results))}
  end
end
