defmodule Defguard do
  @moduledoc """
  Documentation for Defguard.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import Defguard, only: :macros
    end
  end


  defmacro def(head, body) do
    env = __CALLER__
    heads = walk_head(env, head)
    # IO.inspect {:DEFGUARD, :DEF, head, body, heads}
    {:def, [context: Elixir, import: Kernel], [heads, body]}
  end


  # def walk_head({:when, when_meta, [head_ast, {:when, _, [when_ast, _]}=more_whens]}) do
  #   [create_head(when_meta, head_ast, when_ast) | walk_head(more_whens)]
  # end
  def walk_head(env, {:when, when_meta, [head_ast, when_ast]}) do
    create_head(env, when_meta, head_ast, when_ast)
  end
  def walk_head(_env, ast), do: ast

  def create_head(env, when_meta, head_ast, when_ast) do
    {head_ast, when_ast} = process_when(env, head_ast, when_ast)
    # IO.inspect {:DEFGUARD, :CREATE_HEAD, when_meta, head_ast, when_ast}
    {:when, when_meta, [head_ast, when_ast]}
  end

  # def process_when(env, head_ast, {{:., _, [{:__aliases__, _, [module]}, guard]}, _, args}) when is_atom(module) and is_atom(guard) do
  #   # IO.inspect {:PROCESSING_WHEN, head_ast, module, guard, args}
  #   # case :erlang.function_exported(view_module, :menu, 4)
  #   # {head_ast, nil}
  # end
  def process_when(env, head_ast, {guard_ast, _, args}) when is_atom(guard_ast) do
    module = get_import_from_env(env, guard_ast, length(args))
    # IO.inspect {:PROCESSING_WHEN, head_ast, module, guard_ast, args}
    {head_ast, guard} = guard_head(env, head_ast, module, guard_ast, args)
    {head_ast, guard}
  end


  # TODO:  Sanitize variable names inside defguard calls in the matcher segment
  def guard_head(_env, head_ast, module, fun, args) do
    {var_matches, guard} = _guard_spec = apply(module, fun, args)
    IO.inspect {:GUARD_HEAD, head_ast, module, fun, args, _guard_spec}
    head_ast = Macro.postwalk(head_ast, fn
      {varname, _meta, nil} = ast when is_atom(varname) ->
        IO.inspect {:GUARD_HEAD, :INNER, varname, var_matches[varname], var_matches}
        if var_matches[varname] do
          {:=, [], [ast, var_matches[varname]]}
        else
          ast
        end
      ast ->
        # IO.inspect {:UNHANDLED_AST, ast}
        ast
    end)
    {head_ast, guard}
  end


  def get_import_from_env(%{functions: funcs}, fun, arity) do
    Enum.find_value(funcs, nil, fn {module, funs} ->
      if {fun, arity} in funs, do: module, else: false
    end)
  end



  def impl_defguard_heads([], []), do: []
  def impl_defguard_heads([{:__aliases__, _, [name]} = arg | args], [matcher | matchers]) when is_atom(name) do
    IO.inspect {:impl_defguard_heads, arg, matcher}
    kv = {name, Macro.escape(matcher)}
    rest = impl_defguard_heads(args, matchers)
    {kv, rest}
  end
  def impl_defguard_heads([{name, _meta, name_args} = arg | args], [matcher | matchers]) when is_atom(name) and is_atom(name_args) do
    IO.inspect {:impl_defguard_heads, arg, matcher}
    kv = {arg, Macro.escape(matcher)}
    rest = impl_defguard_heads(args, matchers)
    [kv, rest]
  end


  def impl_defguard_simplify_heads(heads) do
    IO.inspect {:impl_defguard_simplify_heads, heads}
    Enum.map(heads, fn
      {{name, _, nil}, guard} when is_atom(name) -> {name, guard}
      kv -> kv
    end)
  end

  def impl_defguard_refine_guards_by_heads(guards, heads) do
    IO.inspect {:impl_defguard_refine_guards_by_heads, guards, heads}
    guards
  end


  # defmacro defguard({:when, _, [{name, meta, args_ast} | when_asts]}) when is_atom(name) do
  defmacro defguard({:when, _, [{name, meta, args_ast}, when_ast]}) when is_atom(name) do
    args =
      Enum.with_index(args_ast)
      |> Enum.map(fn {_, idx} ->
        Macro.var(String.to_atom("var_#{idx}"), __MODULE__)
      end)
    # IO.inspect {:DEFGUARD, :defguard, name, args_ast, when_ast, args}
    {:def, [context: __MODULE__, import: Kernel] ++ meta, [{name, [context: __MODULE__], args}, [do: quote do
      # matchers = unquote(Macro.escape(args_ast))
      # heads = Defguard.impl_defguard_heads(unquote(args), matchers)
      heads = unquote(impl_defguard_heads(args, args_ast)) |> Defguard.impl_defguard_simplify_heads()
      guards = unquote(Macro.escape(when_ast)) |> Defguard.impl_defguard_refine_guards_by_heads(heads)
      {heads, guards}
    end]]}
    |> IO.inspect
  end
end
