defmodule CosmosDbEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias CosmosDbEx.Config

  @impl true
  def start(_type, _args) do
    children = [
      finch_child_spec()
      # Starts a worker by calling: Test1.Worker.start_link(arg)
      # {Test1.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CosmosDbEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp finch_child_spec do
    {
      Finch,
      name: __MODULE__,
      pools: %{
        :default => [size: 10],
        get_cosmos_host_url() => [size: 32, count: 8]
      }
    }
  end

  defp get_cosmos_host_url do
    "https://#{Config.get_cosmos_host_url()}"
  end
end
