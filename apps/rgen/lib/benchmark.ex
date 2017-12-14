defmodule Benchmark do
  @moduledoc """
  Benchmarking module
  """
  @doc """
  Run benchmark
  """
  def run(s_hash_routine, s_charset, n_min_length, n_max_length, n_table_index) do
    # Potential for using GenServer ChainWalker
    chain_walker_context = ChainWalker.set_hash_routine(s_hash_routine)
    |> ChainWalker.set_charset(s_charset, n_min_length, n_max_length)
    |> ChainWalker.set_table_index(n_table_index)
  end
end
