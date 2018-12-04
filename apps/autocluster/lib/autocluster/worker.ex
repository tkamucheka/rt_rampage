defmodule AutoCluster.Worker do
  require Logger
  use GenServer

  @name {:global, __MODULE__}

  # Client API / Helper functions
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def connect(node) do
    GenServer.cast @name, {:connect, node}
  end

  def disconnect(node) do
    GenServer.cast @name, {:disconnect, node}
  end

  def monitor do
    GenServer.cast @name, {:monitor, Process.whereis(:cluster_monitor) }
  end

  defp monitor_cluster do
    GenServer.cast @name, :monitor_cluster
  end

  # GenServer API / Callbacks
  @impl true
  def init(state) do
    monitor()
    # Application.ensure_all_started :libcluster
    {:ok, state}
  end

  def handle_cast({:connect, node}, state) do
    Logger.info "Going to connect up node #{inspect node}..."
    :net_kernel.connect_node(node)
  end

  def handle_cast({:disconnect, node}, state) do
    Logger.info "Going to disconnect node #{inspect node}..."
    :net_kernel.disconnect(node)
  end

  def handle_cast({:monitor, nil}, state) do
    pid = spawn fn ->
      Logger.info "Starting node monitoring process"
      :net_kernel.monitor_nodes true
      monitor_cluster()
    end

    Process.register pid, :cluster_monitor
    {:noreply, state}
  end

  @impl true
  def handle_cast({:monitor, _}, state) do
    Logger.info "Already monitoring!"
    {:noreply, state}
  end

  @impl true
  def handle_cast(:monitor_cluster, state) do
    AutoCluster.visible_nodes()
    receive do
      {:nodeup, node}   ->
        Logger.info "Node joined: #{inspect node}"
        Process.send self(), {:nodeup, node}, state
        monitor_cluster()
      {:nodedown, node} ->
        Logger.info "Node departed: #{inspect node}"
        Process.send self(), {:nodedown, node}, state
        monitor_cluster()
      x -> Logger.error "Node failure: #{inspect x}"
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:connected_nodes, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    {:noreply, [state | node]}
  end
  @impl true
  def handle_info({:nodedown, node}, state) do
    {:noreply, [state | node]}
  end

  @impl true
  def handle_info(_msg, state) do
    Logger.warn "Unknown message"
    {:noreply, state}
  end

end
