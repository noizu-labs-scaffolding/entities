
#================================
# ERP methods
#================================
defmodule Noizu.Entity.Meta.IntegerIdentifier do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  def format_identifier(m, identifier, _) do
    identifier
  end

  #----------------
  #
  #----------------
  def kind(m, id) when is_integer(id), do: {:ok, m}
  def kind(m, R.ref(module: m)), do: {:ok, m}
  def kind(m, %{__struct__: m}), do: {:ok, m}
  def kind(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          String.trim_leading(ref, "ref.#{sref}.")
          |> Integer.parse()
          |> case do
               {identifier, ""} when is_integer(identifier) -> {:ok, m}
               _ -> {:error, {:unsupported, ref}}
             end
        :else -> {:error, {:unsupported, ref}}
      end
    end
  end
  def kind(_m, ref), do: {:error, {:unsupported, ref}}

  def id(m, id) when is_integer(id), do: {:ok, id}
  def id(m, R.ref(module: m, identifier: id)) when is_integer(id), do: {:ok, id}
  def id(m, %{__struct__: m, identifier: id}) when is_integer(id), do: {:ok, id}
  def id(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          String.trim_leading(ref, "ref.#{sref}.")
          |> Integer.parse()
          |> case do
               {identifier, ""} when is_integer(identifier) -> {:ok, identifier}
               _ -> {:error, {:unsupported, ref}}
             end
        :else -> {:error, {:unsupported, ref}}
      end
    end
  end
  def id(_m, ref), do: {:error, {:unsupported, ref}}

  def ref(m, id) when is_integer(id), do: {:ok, R.ref(module: m, identifier: id)}
  def ref(m, R.ref(module: m, identifier: id)) when is_integer(id), do: {:ok, R.ref(module: m, identifier: id)}
  def ref(m, %{__struct__: m, identifier: id}) when is_integer(id), do: {:ok, R.ref(module: m, identifier: id)}
  def ref(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          String.trim_leading(ref, "ref.#{sref}.")
          |> Integer.parse()
          |> case do
               {identifier, ""} when is_integer(identifier) -> {:ok, R.ref(module: m, identifier: identifier)}
               _ -> {:error, {:unsupported, ref}}
             end
        :else -> {:error, {:unsupported, ref}}
      end
    end
  end
  def ref(_m, ref), do: {:error, {:unsupported, ref}}

  def sref(m, id) when is_integer(id) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      {:ok, "ref.#{sref}.#{id}"}
    end
  end
  def sref(m, R.ref(module: m, identifier: id)) when is_integer(id) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      {:ok, "ref.#{sref}.#{id}"}
    end
  end
  def sref(m, %{__struct__: m, identifier: id}) when is_integer(id) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      {:ok, "ref.#{sref}.#{id}"}
    end
  end
  def sref(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          String.trim_leading(ref, "ref.#{sref}.")
          |> Integer.parse()
          |> case do
               {identifier, ""} when is_integer(identifier) -> {:ok, "ref.#{sref}.#{identifier}"}
               _ -> {:error, {:unsupported, ref}}
             end
        :else -> {:error, {:unsupported, ref}}
      end
    end
  end
  def sref(_m, ref), do: {:error, {:unsupported, ref}}



  def entity(m, id, context) when is_integer(id), do: apply(m, :entity, [R.ref(module: m, identifier: id), context])
  def entity(m, R.ref(module: m, identifier: id) = ref, context) when is_integer(id) do
    with repo <- Noizu.Entity.Meta.repo(ref),
         {:ok, repo} <- repo && {:ok, repo} || {:error, {m, :repo_not_foundf}}
      do
      apply(repo, :get, [ref, context, []])
    end
  end
  def entity(m, %{__struct__: m, identifier: id} = ref, _context) when is_integer(id), do: {:ok, ref}
  def entity(m, "ref." <> _ = ref, context) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          String.trim_leading(ref, "ref.#{sref}.")
          |> Integer.parse()
          |> case do
               {identifier, ""} when is_integer(identifier) -> apply(m, :entity, [R.ref(module: m, identifier: identifier), context])
               _ -> {:error, {:unsupported, ref}}
             end
        :else -> {:error, {:unsupported, ref}}
      end
    end
  end
  def entity(_m, ref, _context), do: {:error, {:unsupported, ref}}


end
