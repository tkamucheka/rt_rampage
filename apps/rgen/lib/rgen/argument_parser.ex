defmodule ArgumentParser do
  @doc """
  Parse arguments
  """
  def parse_args(args) do
    # Default options
    options = %{part: ""}
    # Parse args
    cmd_opts =
      OptionParser.parse(
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

    # Merge options
    case cmd_opts do
      {[], [], _} -> :help
      {[help: true], _, _} -> :help
      {[], args, []} -> {options, args}
      {opts, args, []} -> {Enum.into(opts, options), args}
      {opts, args, bad_args} -> {Enum.into(merge_opts(opts, bad_args), options), args}
      _ -> :help
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
    |> Enum.flat_map(fn x -> Tuple.to_list(x) end)
    |> Enum.filter(fn str -> str end)
    |> Enum.map(fn str -> String.replace(str, ~r/^\-([^-]+)/, "--\\1") end)
    |> OptionParser.parse()
    |> Tuple.to_list()
    |> List.first()
  end

  def validate(args, docs) do
    IO.puts(docs)
    args
  end
end
