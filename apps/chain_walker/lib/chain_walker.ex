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
      { :ok, routine } -> %ChainWalkerContext{ hash_routine: routine }
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
    hash_routines = %HashRoutines{}

    routine = s_hash_routine
    |> String.downcase
    |> String.to_atom

    case Map.has_key?(hash_routines, routine) do
      true  -> { :ok, Map.get(hash_routines, routine) }
      _     -> { :error, "Hash algorithm '#{routine}', is not supported!" }
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
    |> set_min_password_length(n_min_length, n_max_length)
    |> set_max_password_length(n_min_length, n_max_length)
    |> set_plain_space_up_to_x(n_min_length, n_max_length)
    #|> set_plain_space_total()
  end

  def set_charset(chain_walker_context, s_charset) do
    charsets = %{ alpha: 'abc' }
    case validate_arg(charsets, s_charset) do
      { :ok, charset }  -> %{ chain_walker_context | charset: Map.get(charsets, charset) }
      { _, reason }     -> raise ArgumentError, message: reason
    end
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
      { :ok, min_length } -> %{ chain_walker_context | min_length: min_length }
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
      { :ok, max_length } -> %{ chain_walker_context | max_length: max_length }
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
    plain_space_upto_x = Enum.map(1..(max_plain_len+1), fn _ -> 0 end)
    n_temp = 1

    for i <- 1..n_max_length do
      # plain_space_upto_x = List.update_at(plain_space_upto_x, i, &(&1 = 1))
      # n_temp = n_temp * Map.get(chain_walker_context, :charset_length)
      # if i >= n_min_length do
        # List.update_at plain_space_upto_x, i, fn _ ->
        #   IO.puts "index: #{i}\t plain_space_var: #{Enum.at(plain_space_upto_x, i)}\ttemp_value: #{n_temp}"
        #   Enum.at(plain_space_upto_x, i) + n_temp
        # end
        # plain_space_upto_x = List.update_at(plain_space_upto_x, 0, &(&1 = 1))
      # end
    end

    # r = Enum.map(plain_space_upto_x, (any() -> any()))

    r = for i <- 1..n_max_length do
      n_temp = n_temp * Map.get(chain_walker_context, :charset_length)
      if i < n_min_length do
        List.update_at(plain_space_upto_x, i, &(&1 = 0))
      else
        List.update_at(plain_space_upto_x, i, &(&1 = Enum.at(plain_space_upto_x, i) +1))
      end
    end

    for i <- 1..n_max_length, do: Enum.at(plain_space_upto_x, i)
    |> List.update_at(i, fn _ -> 1 end)

    IO.inspect plain_space_upto_x
    # for elem <- 1..n_max_length, do

    # updated_list = List.update_at(plain_space_upto_x, 0, &(&1 = 1))
    %{ chain_walker_context | plain_space_upto_x: plain_space_upto_x }
  end

  @doc """
  Set plain space total
  """
  def set_plain_space_total(chain_walker_context) do
    chain_walker_context
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
    %{ chain_walker_context | table_index: n_table_index }
  end

  @doc """
  Generate random index
  """
  def generate_random_index(chain_walker_context) do
    # <<random_bytes::64>> = :crypto.rand_bytes(8)
    # n_index = rem(random_bytes, Map.get(chain_walker_context, nPlainSpaceTotal))
    # %{ chain_walker_context | m_n_index: n_index }
  end
end
