
defmodule StructEx do
  import Defguard
  defguard is_struct(%{__struct__: struct_name}) when is_atom(struct_name)
  defguard is_struct(%{__struct__: struct_name}, substruct_name) when is_atom(struct_name) and struct_name === substruct_name
  defguard is_exception(%{__struct__: struct_name, __exception__: true}) when is_atom(struct_name)
end

defmodule Testering do
  use Defguard
  import StructEx

  # def blah(_blah_struct, struct_name \\ Blah) when is_struct(_blah_struct, struct_name), do: 1
  def blah(_any_struct) when is_struct(_any_struct), do: 2
  def blah(_), do: 0

  def blorp(_exc) when is_exception(_exc), do: "exceptioned"
  def blorp(val), do: "No-exception:  #{inspect val}"
end

# IO.inspect {:BLAH1, Testering.blah(%{__struct__: Blah})}
# IO.inspect {:BLAH2, Testering.blah(42)}
# %ArithmeticError{} |> Testering.blorp()

ExUnit.start()
