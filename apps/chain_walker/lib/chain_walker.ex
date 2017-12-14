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
    |> set_max_password_length(n_max_length)
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

  
  def set_max_password_length(chain_walker_context, n_max_length) do

  end

  def set_table_index(%ChainWalkerContext{}, n_table_index) do
    n_table_index
  end
end
