defmodule Benchmark do
  @moduledoc """
  Benchmarking module
  """

  # defmacro bench_hashing(hash_routine, loops, do: block) do
  #   quote do
  #     start = System.system_time
  #     Enum.each 0..unquote(loops), fn(_) ->
  #       unquote(block)
  #     end
  #     finish = System.system_time
  #     f_time = (finish-start) / 1000000
  #     speed  = unquote(loops) / f_time |> Float.round(2)
  #     IO.puts "#{unquote(hash_routine)} hash speed #{speed}K /s"
  #   end
  # end

  # defmacro bench_with(loops, do: block) do
  #   quote do
  #     start = System.system_time
  #     unquote(block)
  #     finish = System.system_time
  #     f_time = (finish-start) / 1000000
  #     speed  = unquote(loops) / f_time |> Float.round(2)
  #   end
  # end

  def measure(total_loops, function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
    |> (&round(total_loops / &1)).()
    |> Kernel./(1_000)
  end

  @doc """
  Run benchmark
  """
  def run(s_hash_routine, s_charset, n_min_length, n_max_length, n_table_index) do
    total_loops = 2_500_000
    # Potential for using GenServer ChainWalker
    chain_walker_context =
      ChainWalker.set_hash_routine(s_hash_routine)
      |> ChainWalker.set_charset_opts(s_charset, n_min_length, n_max_length)
      |> ChainWalker.set_table_index(n_table_index)

    # Bench hashes per second
    # Setup ChainWalker
    cwc1 =
      ChainWalker.generate_random_index(chain_walker_context)
      |> ChainWalker.index_to_plain()

    # Run benchmark
    result =
      measure(total_loops, fn ->
        Enum.each(0..total_loops, fn _ ->
          ChainWalker.plain_to_hash(cwc1)
        end)
      end)

    IO.puts("#{cwc1.m_hash_routine.name} hash speed #{result}K /s")

    # Bench chain steps per second
    # Setup ChainWalker
    cwc2 = ChainWalker.generate_random_index(chain_walker_context)
    # Run benchmark
    result =
      measure(total_loops, fn ->
        Enum.each(0..total_loops, fn i ->
          ChainWalker.index_to_plain(cwc2)
          |> ChainWalker.plain_to_hash()
          |> ChainWalker.hash_to_index(i)
        end)
      end)

    IO.puts("#{cwc2.m_hash_routine.name} step speed #{result}K /s")

    Benchee.run(
      %{
        "Hashing" => fn ->
          ChainWalker.plain_to_hash(cwc1)
        end,
        "Steps" => fn ->
          ChainWalker.index_to_plain(cwc2)
          |> ChainWalker.plain_to_hash()
          |> ChainWalker.hash_to_index(0)
        end
      },
      print: [benchmarking: false]
    )
  end
end
