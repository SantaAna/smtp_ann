defmodule SmtpAnn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SmtpAnnWeb.Telemetry,
      SmtpAnn.Repo,
      {DNSCluster, query: Application.get_env(:smtp_ann, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SmtpAnn.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SmtpAnn.Finch},
      # Start a worker by calling: SmtpAnn.Worker.start_link(arg)
      # {SmtpAnn.Worker, arg},
      # Start to serve requests, typically the last entry
      SmtpAnnWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmtpAnn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SmtpAnnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
