defmodule Rgen.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Rgen.Worker.start_link(arg)
      # {Rgen.Worker, arg},
      # {AutoCluster.Worker, []},
      {Rgen.TableGenerator, []},
      {Task.Supervisor, [name: Rgen.TaskSupervisor]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rgen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
