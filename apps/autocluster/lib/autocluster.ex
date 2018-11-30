defmodule AutoCluster do
  @moduledoc """
  Documentation for AutoCluster.
  """

  def all_nodes do
    Node.list(:known)
      |> display_nodes("All Nodes")
  end

  def visible_nodes do
    Node.list()
      |> display_nodes("Visible Nodes")
  end

  defp display_nodes(nodes, title) do
    IO.puts "#{stars()} #{title} #{stars()}"
    display_nodes(nodes)
  end

  defp display_nodes([]), do: IO.puts "Not connected to any cluster. We are alone.\n"
  defp display_nodes(nodes) when is_list(nodes) do
    IO.puts "Nodes in our cluster, including ourselves:"

    [Node.self()|nodes]
    |> Enum.sort
    |> Enum.dedup
    |> Enum.each(fn node -> IO.puts "     #{inspect node}\n" end)
  end

  # defp good_news_marker, do: IO.ANSI.green() <> String.duplicate(<<0x1F603 :: utf8>>, 5) <> IO.ANSI.reset()
  # defp bad_news_marker, do: IO.ANSI.red() <> String.duplicate(<<0x1F630 :: utf8>>, 5) <> IO.ANSI.reset()
  defp stars, do: String.duplicate "*", 10
end
