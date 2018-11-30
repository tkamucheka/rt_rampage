defmodule ChainWalker do
  @moduledoc """
  Documentation for ChainWalker.
  """

  @doc """
  Set the hash routine to use for hashing during operation.

  ## Parameters
    - `s_hash_routine`: String to select the hashing algorithm to use.

  ## Examples
      iex> ChainWalker.set_hash_routine("md5")
      %ChainWalkerContext{charset: nil, hash_routine: :md5, max_length: nil, min_length: nil, table_index: nil}
  """
  def set_hash_routine(s_hash_routine) do
    case validate_routine(s_hash_routine) do
      { :ok, routine } -> %ChainWalkerContext{ m_hash_routine: routine }
      { :error, reason } -> raise ArgumentError, message: reason
    end
  end

  @doc """
  Validates the given `hash_algorithm` argument, `s_hash_routine` by checking if the hash algorithm is supported.

  ## Parameters
    - `s_hash_routine`: String to select the hashing algorithm to use.

  ## Examples
      iex> ChainWalker.validate_routine("md5")
      {:ok, :md5}
  """
  def validate_routine(s_hash_routine) do
    routine = Enum.find HashRoutines.setup, fn(routine) ->
      match?(%{name: ^s_hash_routine}, routine)
    end

    case routine do
      %{} -> { :ok, routine }
      nil -> { :error, "Hash algorithm #{s_hash_routine}, is not supported!" }
    end
  end

  @doc """
  Validates a given `argument`, by checking if it exists as a key in the `struct` provided.

  ## Parameters
    - `struct`: Struct containing valid options and their values.
    - `argument`: Argument entered to be validated.

  ## Examples
      iex> ChainWalker.validate_arg(%HashRoutines{}, "md5")
      {:ok, :md5}
      iex> ChainWalker.validate_arg(%HashRoutines{}, "unknown_routine")
      {:error, "Incorrect argument 'unknown_routine', is not supported!"}
  """
  def validate_arg(struct, argument) do
    arg = argument
    |> String.downcase
    |> String.to_atom

    case Map.has_key?(struct, arg) do
      true  -> { :ok, arg }
      _     -> { :error, "Incorrect argument '#{argument}', is not supported!" }
    end
  end

  @doc """
  Set charset and minimum and maximum password length

  ## Parameters
    - `chain_walker_context`: %ChainWalkerContext{}
    - `s_charset`: Candidate character set.
    - `n_min_length`: Minimum plain text password length.
    - `n_max_length`: Maximum plain text password length.

  ## Returns
    - `%ChainWalkerContext{}`

  ## Examples
      iex> ChainWalker.set_charset_opts(%ChainWalkerContext{}, "alpha", 1, 2)
      %ChainWalkerContext{charset: 'abc', hash_routine: nil, min_length: 1, max_length: 2, table_index: nil}
  """
  def set_charset_opts(chain_walker_context, s_charset, n_min_length, n_max_length) do
    set_charset(chain_walker_context, s_charset)
    |> set_charset_length
    |> set_min_password_length(n_min_length, n_max_length)
    |> set_max_password_length(n_min_length, n_max_length)
    |> set_plain_space_up_to_x(n_min_length, n_max_length)
    |> set_plain_space_total(n_max_length)
  end

  def set_charset(chain_walker_context, s_charset) do
    charsets = %{
      "alpha": 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      "alpha-numeric": 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
      "alpha-numeric-symbol14": 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+=',
      "all": 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+=~`[]{}|\\:;"\'<>,.?/',
      "numeric": '0123456789',
      "loweralpha": 'abcdefghijklmnopqrstuvwxyz',
      "loweralpha-numeric": 'abcdefghijklmnopqrstuvwxyz0123456789'
    }
    case validate_arg(charsets, s_charset) do
      { :ok, charset }  -> %{ chain_walker_context | s_charset: Map.get(charsets, charset) }
      { _, reason }     -> raise ArgumentError, message: reason
    end
  end

  def set_charset_length(chain_walker_context) do
    length =
      Map.get(chain_walker_context, :s_charset)
      |> length
    %{ chain_walker_context | n_charset_length: length }
  end

  @doc """
  Set minimum plain text password length to be included in the rainbow table.

  ## Parameters
    - `chain_walker_context`: %ChainWalkerContext{}
    - `n_min_length`: Minimum length for plain text passwords.
    - `n_max_length`: Maximum length for plain text passwords.

  ## Returns
    - `%ChainWalkerContext{}`

  ## Examples
      iex> ChainWalker.set_min_password_length(%ChainWalkerContext{}, 1, 2)
      %ChainWalkerContext{charset: nil, hash_routine: nil, max_length: nil, min_length: 1, table_index: nil}
  """
  def set_min_password_length(chain_walker_context, n_min_length, n_max_length) do
    case validate_min_password_length(n_min_length, n_max_length) do
      { :ok, min_length } -> %{ chain_walker_context | n_min_length: min_length }
      { _, reason }       -> raise ArgumentError, message: reason
    end
  end

  @doc """
  Validates correctness of minimum password length argument.

  ## Parameters
    - `n_min_length`: Minimum plain text password length.
    - `n_max_length`: Maximum plain text password length.

  ## Returns
    - `{ :ok, n_min_length }`
    - `{ :error, reason }`

  ## Examples
      iex> ChainWalker.validate_min_password_length(1, 2)
      {:ok, 1}
      iex> ChainWalker.validate_min_password_length(2, 1)
      {:error, "Bad argument: Minimum password length (2) cannot be greater than maximum length (1)."}
      iex> ChainWalker.validate_min_password_length(0, 2)
      {:error, "Bad argument: Mininum password length (0) cannot be zero or less."}
      iex> ChainWalker.validate_min_password_length(10, 10)
      {:error, "Bad argument: Minimum password length (10) cannot be greater than maximum supported password length (9)." }
  """
  def validate_min_password_length(n_min_length, n_max_length) do
    cond do
      # Check if password minimum length is greater than maximum length
      n_min_length > n_max_length ->
        { :error, "Bad argument: Minimum password length (#{n_min_length}) cannot be greater than maximum length (#{n_max_length})." }
      # Check if minimum password length is less than or equal to zero.
      n_min_length <= 0           ->
        { :error, "Bad argument: Mininum password length (#{n_min_length}) cannot be zero or less." }
      # Check if minimum password length is greater than maximum supported length (9).
      n_min_length >= 10          ->
        { :error, "Bad argument: Minimum password length (#{n_min_length}) cannot be greater than maximum supported password length (9)." }
      # Otherwise return :ok
      true                        ->
        { :ok, n_min_length }
    end
  end

  @doc """
  Set maximum plain text password length to be included in the rainbow table.

    ## Parameters
      - `chain_walker_context`: %ChainWalkerContext{}
      - `n_min_length`: Minimum length for plain text passwords.
      - `n_max_length`: Maximum length for plain text passwords.

    ## Returns
      - `%ChainWalkerContext{}`

    ## Examples
        iex> ChainWalker.set_max_password_length(%ChainWalkerContext{}, 1, 2)
        %ChainWalkerContext{charset: nil, hash_routine: nil, max_length: 2, min_length: nil, table_index: nil}
  """
  def set_max_password_length(chain_walker_context, n_min_length, n_max_length) do
    case validate_max_password_length(n_min_length, n_max_length) do
      { :ok, max_length } -> %{ chain_walker_context | n_max_length: max_length }
      { _, reason }       -> raise ArgumentError, message: reason
    end
  end

  @doc """
  Validates correctness of maximum password length argument.

  ## Parameters
    - `n_min_length`: Minimum plain text password length.
    - `n_max_length`: Maximum plain text password length.

  ## Returns
    - `{ :ok, n_max_length }`
    - `{ :error, reason }`

  ## Examples
      iex> ChainWalker.validate_max_password_length(1, 2)
      {:ok, 2}
      iex> ChainWalker.validate_max_password_length(2, 1)
      {:error, "Bad argument: Maximum password length (1) cannot be lesser than minimum length (2)."}
      iex> ChainWalker.validate_max_password_length(0, 0)
      {:error, "Bad argument: Maximum password length (0) cannot be zero or less."}
      iex> ChainWalker.validate_max_password_length(1, 10)
      {:error, "Bad argument: Maximum password length (10) cannot be greater than maximum supported password length (9)." }
  """
  def validate_max_password_length(n_min_length, n_max_length) do
    cond do
      # Check maximum length is not lesser than minimum length
      n_min_length > n_max_length ->
        { :error, "Bad argument: Maximum password length (#{n_max_length}) cannot be lesser than minimum length (#{n_min_length})." }
      # Check maximum password length is greater than zero
      n_max_length <= 0           ->
        { :error, "Bad argument: Maximum password length (#{n_max_length}) cannot be zero or less." }
      # Check maximum password length is not more than supported length
      n_max_length >= 10          ->
        { :error, "Bad argument: Maximum password length (#{n_max_length}) cannot be greater than maximum supported password length (9)." }
      # Otherwise return :ok
      true                        ->
        { :ok, n_max_length }
    end
  end

  @doc """
  Set plain space upto x
  """
  def set_plain_space_up_to_x(chain_walker_context, n_min_length, n_max_length) do
    max_plain_len = 256

    n_plain_space_upto_x = Enum.map(1..(max_plain_len+1), &(&1=0))
    charset_length = Map.get(chain_walker_context, :n_charset_length)

    result = index_builder(n_plain_space_upto_x, 1, 1, charset_length, n_min_length, n_max_length)

    %{ chain_walker_context | n_plain_space_upto_x: result }
  end

  def index_builder(n_plain_space_upto_x, index, temp, n_plain_charset_length, n_min_length, n_max_length) do
    n_temp = temp * n_plain_charset_length

    n_plain_space_upto_x =
      case index >= n_min_length do
        true  ->
          x = Enum.at(n_plain_space_upto_x, index-1) + n_temp
          List.update_at(n_plain_space_upto_x, index, &(&1 = x))
        _     -> n_plain_space_upto_x
      end

    case index <= n_max_length do
      true  ->
        index_builder(n_plain_space_upto_x, index+1, n_temp, n_plain_charset_length, n_min_length, n_max_length)
      _     -> n_plain_space_upto_x
    end
  end

  @doc """
  Set plain space total
  """
  def set_plain_space_total(chain_walker_context, n_max_length) do
    total = Map.get(chain_walker_context, :n_plain_space_upto_x)
    |> Enum.at(n_max_length)
    %{ chain_walker_context | n_plain_space_total: total }
  end

  @doc """
  Set table index for current operation.

  ## Parameters
    - `chain_walker_context`: %ChainWalkerContext{}
    - `n_table_index`: Positive integer indicating table index

  ## Returns
    - `%ChainWalkerContext{}`

  ## Examples
      iex> ChainWalker.set_table_index(%ChainWalkerContext{}, 0)
      %ChainWalkerContext{charset: nil, hash_routine: nil, max_length: nil,
       min_length: nil, table_index: 0}
  """
  def set_table_index(chain_walker_context, n_table_index) do
    if n_table_index < 0, do: raise ArgumentError, message: "Table index (#{n_table_index}) cannot be less than zero (0)."

    n_reduce_offset = 65536 * n_table_index

    %{ chain_walker_context |
      n_table_index: n_table_index,
      n_reduce_offset: n_reduce_offset }
  end

  @doc """
  Generate random index
  """
  def generate_random_index(chain_walker_context) do
    <<random_bytes::64>> = :crypto.strong_rand_bytes(8)
    n_index = rem(random_bytes, Map.get(chain_walker_context, :n_plain_space_total))
    %{ chain_walker_context | n_index: n_index }
  end

  def set_current_index(chain_walker_context, index) do
    n_index =
      rem(index, chain_walker_context.n_plain_space_total)
    %{ chain_walker_context | n_index: n_index }
  end

  @doc """
  Index to plain
  """
  def index_to_plain(cwc) do
    cwc
    |> set_plain_length(cwc.n_min_length, cwc.n_max_length - 1)
    |> get_index_of_x
    |> build_plain
  end

  # defp set_plain_length(chain_walker_context, index) do
  #   IO.inspect "n_index: #{chain_walker_context.n_index}"
  #   IO.inspect "psux: #{Enum.at(chain_walker_context.n_plain_space_upto_x, index)}"
  #
  #   case chain_walker_context.n_index >= Enum.at(chain_walker_context.n_plain_space_upto_x, index) do
  #     true  ->
  #       %{ chain_walker_context | n_plain_length: index+1 }
  #     _     ->
  #       if index >= chain_walker_context.n_min_length do
  #         set_plain_length(chain_walker_context, index-1)
  #       end
  #   end
  # end

  defp set_plain_length(cwc, n_min_length, index)
  when index >= n_min_length - 1 do
    case cwc.n_index >= Enum.at(cwc.n_plain_space_upto_x, index) do
      true -> %{ cwc | n_plain_length: index + 1 }
      _    -> set_plain_length(cwc, n_min_length, index - 1)
    end
  end

  defp get_index_of_x(chain_walker_context) do
    n_index_of_x = chain_walker_context.n_index - Enum.at(chain_walker_context.n_plain_space_upto_x, chain_walker_context.n_plain_length-1)

    { chain_walker_context, n_index_of_x }
  end

  defp build_plain({ chain_walker_context, n_index_of_x }) do
    m_plain = for _ <- 1..chain_walker_context.n_max_length, do: ""
    build_plain(chain_walker_context, n_index_of_x, m_plain, chain_walker_context.n_plain_length-1)
  end

  defp build_plain(chain_walker_context, n_index_of_x, m_plain, index)
  when index >= 0 do
    char = Enum.at(chain_walker_context.s_charset, rem(n_index_of_x, chain_walker_context.n_charset_length))
    l = List.update_at(m_plain, index, &(&1 = char))
    n_index_of_x = div(n_index_of_x, chain_walker_context.n_charset_length)
    build_plain(chain_walker_context, n_index_of_x, l, index-1)
  end

  defp build_plain(chain_walker_context, _n_index_of_x, m_plain, index)
  when index < 0 do
    %{ chain_walker_context | s_plain: to_string(m_plain) }
  end

  @doc """
    Create hash from plain text
  """
  def plain_to_hash(chain_walker_context) do
    %{ m_hash_routine: routine, s_plain: password } = chain_walker_context
    set_hash(chain_walker_context, routine.hash.(password))
  end

  defp set_hash(chain_walker_context, hash) do
    %{ chain_walker_context | s_hash: hash }
  end

  def hash_to_index(chain_walker_context, n_pos) do
    # hash = chain_walker_context.s_hash |> String.to_integer(16)
    offset = chain_walker_context.n_reduce_offset
    plain_space_total = chain_walker_context.n_plain_space_total

    IO.inspect chain_walker_context.s_hash

    reduced_hash = reduce_hash(chain_walker_context.s_hash)

    # IO.inspect reduced_hash

    n_index = rem(reduced_hash + offset + n_pos, plain_space_total)

    %{ chain_walker_context | n_index: n_index }
  end

  def reduce_hash(s_hash) do
    s_hash
    |> String.slice(0..3)
    |> String.reverse
    |> Base.encode16
    |> String.to_integer(16)
  end

  @doc """
  Step function
  Starts chain walking process
  """
  def step(chain_walker_context, n_chain_length) do
    index_to_plain(chain_walker_context)
    |> plain_to_hash
    |> hash_to_index(0)
    |> step(n_chain_length, 0)
  end

  defp step(chain_walker_context, n_chain_length, index)
  when index < n_chain_length do
    # IO.inspect "Leading indices: #{index}"
    index_to_plain(chain_walker_context)
    |> plain_to_hash
    |> hash_to_index(index)
    |> step(n_chain_length, index + 1)
  end

  defp step(chain_walker_context, n_chain_length, index)
  when index >= (n_chain_length) do
    # IO.inspect "Final index: #{index}"
    chain_walker_context
  end
end
