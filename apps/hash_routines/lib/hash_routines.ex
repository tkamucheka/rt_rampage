defmodule HashRoutines do
  @moduledoc """
  Documentation for HashRoutines.
  """

  def setup do
    # add_routine(md5, module, hash_length)
    # [%HashRoutine{}, ...]
    add_routine([], "md5", 16, &(Base.encode16(:crypto.hash(:md5, &1), [case: :lower])))
    |> add_routine("sha1", 16, &(Base.encode16(:crypto.hash(:sha, &1), [case: :lower])))
  end

  defp add_routine(routines, name, hash_length, routine) do
    [
      %HashRoutine{
        name: name,
        hash: routine,
        hash_length: hash_length
      } | routines
    ]
  end
end
