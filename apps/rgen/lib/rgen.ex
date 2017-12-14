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
    options = %{}
    # Parse args
    cmd_opts = OptionParser.parse(
      args,
      switches: [help: :boolean, hashtype: :string],
      aliases: [h: :help]
    )

    # IO.puts cmd_opts

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

  end
end
