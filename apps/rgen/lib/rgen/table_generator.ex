defmodule Rgen.TableGenerator do
  use GenServer

  # Client API
  @impl true
  def init(args) do
    {:ok, args}
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server Callbacks
  # ...
end
