defmodule Rgen do
  @moduledoc """
  Documentation for Rgen.

  usage: rtgen hash_algorithm=<algorithm> \\
	              plain_charset=<path> plain_len_min=<number> plain_len_max=<number> \\
	              rainbow_table_index=<number> \\
	              rainbow_chain_length=<number> rainbow_chain_count=<number> \\
	              file_title_suffix=<any>
	        rtgen hash_algorithm=<algorithm> \\
	              plain_charset=<path> plain_len_min=<number> plain_len_max=<number> \\
	              rainbow_table_index=<number> \\
	              -bench

	hash_algorithm:       available: []
	plain_charset:        use any charset name in charset.txt here
	                       use \"byte\" to specify all 256 characters as the charset of the plaintext
	plain_len_min:        min length of the plaintext
	plain_len_max:        max length of the plaintext
	rainbow_table_index:  index of the rainbow table
	rainbow_chain_length: length of the rainbow chain
	rainbow_chain_count:  count of the rainbow chain to generate
	file_title_suffix:    the string appended to the file title
	                       add your comment of the generated rainbow table here
  -bench:               do some benchmark
  
	example: rtgen lm alpha 1 7 0 100 16 test
	          rtgen md5 byte 4 4 0 100 16 test
	          rtgen sha1 numeric 1 10 0 100 16 test
	          rtgen lm alpha 1 7 0 -bench
  """

  @doc """
  Generate table
  """
  def main(args) do
    args
    |> ArgumentParser.parse_args
    |> process
  end

  @doc """
  Process
  Start table generation
  """
  # def process({_, _}) do
  #   IO.puts "No args given."
  #   System.halt(0)
  # end

  def process(:help) do
    IO.puts(@moduledoc)
    System.halt(0)
  end

  def process({options, _unused_args}) do
    IO.puts("::Options::")
    IO.puts("#{inspect(options)}\n")

    if map_size(options) == 7 do
      if options.benchmark do
        Benchmark.run(
          options.hashtype,
          options.charset,
          options.minlength,
          options.maxlength,
          options.tableindex
        )
      end
      System.halt(0)
    end

    unless map_size(options) == 8 do
      IO.puts(@moduledoc)
      System.halt(0)
    end

    # n_numchains check
    if options.numchains >= 134_217_728 do
      IO.puts("This will generate a table larger than 2GB, which is not supported.")
      IO.puts("Please use a smaller number of chains, (--numchains), less than 134217728.")
    end

    # build chain_walker_context
    chain_walker_context = build_chain_walker_context(options)
    IO.puts("::ChainWalkerContext::")
    IO.puts("#{inspect(chain_walker_context)}\n")

    # build filename
    s_filename = build_filename(options)
    IO.puts("::Filename::")
    IO.puts("#{inspect(s_filename)}\n")

    file = open_rainbow_table_file(s_filename)

    data_length = IO.binread(file, :all) |> String.length()

    IO.inspect(data_length)

    n_data_length = div(data_length, 16) * 16
    n_chain_length = options.chainlength
    n_numchains = options.numchains

    if n_data_length == n_numchains * 16 do
      IO.puts("Precomputation of this rainbow table already finished")
      File.close(file)
      System.halt(0)
    end

    if n_data_length > 0 do
      IO.puts("Continuing from interrupted precomputation...")
    end

    IO.puts("Generating...")

    starting_position = div(n_data_length, 16)
    IO.inspect("Starting position: #{starting_position}")
    IO.inspect("Number Of Chains:  #{n_numchains}")

    AutoCluster.Worker.all_nodes
      |> Enum.map(&(Task.Supervisor.async(
                  {Rgen.TaskSupervisor, &1},
                  fn() -> 1 + 1 end)))
      |> Enum.map(&Task.await/1)
  end

  defp build_chain_walker_context(%{
         hashtype: s_hash_routine,
         charset: s_charset,
         minlength: n_min_length,
         maxlength: n_max_length,
         tableindex: n_table_index
       }) do
    # Setup ChainWalkerContext
    ChainWalker.set_hash_routine(s_hash_routine)
    |> ChainWalker.set_charset_opts(s_charset, n_min_length, n_max_length)
    |> ChainWalker.set_table_index(n_table_index)

    # ChainWalker.dump
  end

  defp build_filename(%{
         hashtype: s_hash_routine,
         charset: s_charset,
         minlength: n_min_length,
         maxlength: n_max_length,
         tableindex: n_table_index,
         chainlength: n_chain_length,
         numchains: n_numchains,
         part: s_filename_suffix
       }) do
    "#{s_hash_routine}_#{s_charset}##{n_min_length}-#{n_max_length}_#{n_table_index}_#{
      n_chain_length
    }x#{n_numchains}_#{s_filename_suffix}.rt"
  end

  defp open_rainbow_table_file(s_filename) do
    # case File.open(s_filename, [:append, :binary]) do
    #   { :ok, file }       -> File.close(file)
    #   { :error, reason }  -> raise File.Error, message: reason
    # end

    case File.open(s_filename, [:read, :write, :binary]) do
      {:ok, file} -> file
      {:error, reason} -> raise File.Error, message: reason
    end
  end
end
