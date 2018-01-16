defmodule Rgen do
  @moduledoc """
  Documentation for Rgen.
  """

  @doc """
  Generate table
  """
  def main(args) do
    args |> parse_args |> process
  end

  @doc """
  Parse arguments
  """
  def parse_args(args) do
    # Default options
    options = %{ part: "" }
    # Parse args
    cmd_opts = OptionParser.parse(
      args,
      switches: [
        help: :boolean,
        hashtype: :string,
        charset: :string,
        minlength: :integer,
        maxlength: :integer,
        chainlength: :integer,
        numchains: :integer,
        tableindex: :integer,
        part: :string,
        benchmark: :boolean
        ],
      aliases: [h: :help]
    )

    case cmd_opts do
      { [], [], _ }             -> :help
      { [help: true], _, _ }    -> :help
      { [], args, [] }          -> { options, args }
      { opts, args, [] }        -> { Enum.into(opts, options), args }
      { opts, args, bad_args }  -> { Enum.into(merge_opts(opts, bad_args), options), args }
      _                         -> :help
    end
  end

  @doc """
  Merge bad options with rest of options
  """
  def merge_opts(opts, bad_args) do
    bad_args |> rehabilitate_args |> Keyword.merge(opts)
  end

  @doc """
  Rehabilitate bad arguments
  """
  def rehabilitate_args(bad_args) do
    bad_args
    |> Enum.flat_map(fn(x) -> Tuple.to_list(x) end)
    |> Enum.filter(fn(str) -> str end)
    |> Enum.map(fn(str) -> String.replace(str, ~r/^\-([^-]+)/, "--\\1") end)
    |> OptionParser.parse
    |> Tuple.to_list
    |> List.first
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
    IO.puts @moduledoc
    System.halt(0)
  end

  def process({options, args}) do
    IO.inspect options
    IO.inspect args

    if Enum.count(options) == 7 do
      if options.benchmark do
        Benchmark.run(options.hashtype, options.charset, options.minlength, options.maxlength, options.tableindex)
      end
    end

    unless Enum.count(options) == 8 do
      IO.puts @moduledoc
      System.halt(0)
    end

    s_hash_routine  = options.hashtype
    s_charset       = options.charset
    n_min_length    = options.minlength
    n_max_length    = options.maxlength
    n_table_index   = options.tableindex

    n_chain_length  = options.chainlength
    n_numchains     = options.numchains
    s_filename_suffix = options.part

    # n_numchains check
    if n_numchains >= 134217728 do
      IO.puts "This will generate a table larger than 2GB, which is not supported."
      IO.puts "Please use a smaller number of chains, (--numchains), less than 134217728."
    end

    # Setup ChainWalkerContext
    chain_walker_context =
      ChainWalker.set_hash_routine(s_hash_routine)
      |> ChainWalker.set_charset_opts(s_charset, n_min_length, n_max_length)
      |> ChainWalker.set_table_index(n_table_index)
      # ChainWalker.dump

    IO.inspect chain_walker_context

    s_filename = "#{s_hash_routine}_#{s_charset}##{n_min_length}-#{n_max_length}_#{n_table_index}_#{n_chain_length}x#{n_numchains}_#{s_filename_suffix}.rt"

    IO.inspect s_filename

    case File.open(s_filename, [:append, :binary]) do
      { :ok, file }       -> File.close(file)
      { :error, reason }  -> raise File.Error, message: reason
    end

    file =
      case File.open(s_filename, [:read, :write, :binary]) do
        { :ok, file } -> file
        { :error, reason } -> raise File.Error, message: reason
      end

    data_length = IO.binread(file, :all) |> String.length

    IO.inspect data_length

    n_data_length = div(data_length, 16) * 16

    if n_data_length == n_numchains * 16 do
      IO.puts "Precomputation of this rainbow table already finished"
      File.close(file)
      System.halt(0)
    end

    if n_data_length > 0 do
      IO.puts "Continuing from interrupted precomputation..."
    end

    IO.puts "Generating..."

    IO.inspect "Starting position: #{div(n_data_length, 16)}"
    IO.inspect "Number Of Chains: #{n_numchains}"

    # start_time = System.system_time
    start_time = :erlang.timestamp
    Enum.each div(n_data_length, 16)..(n_numchains-1), fn(index) ->
      chain_walker_context =
        ChainWalker.generate_random_index(chain_walker_context)

      IO.binwrite file, <<chain_walker_context.n_index::64>>

      chain_walker_context =
        ChainWalker.step(chain_walker_context, n_chain_length)

      IO.binwrite file, <<chain_walker_context.n_index::64>>

      if rem(index+1, 100_000) == 0 || index+1 == n_numchains do
        finish_time = :erlang.timestamp
        n_second =
          :timer.now_diff(finish_time, start_time)
          |> div(1_000_000)

        IO.puts "#{index+1} of #{n_numchains} rainbow chains generated (#{div(n_second, 60)} m #{rem(n_second, 60)} s)"
      end
    end

    File.close(file)
  end
end
