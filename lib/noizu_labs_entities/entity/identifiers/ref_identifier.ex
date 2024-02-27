# ================================
# ERP methods
# ================================
defmodule Noizu.Entity.Meta.RefIdentifier do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  def format_id(m, _, _) do
    raise Noizu.Entity.Identifier.Exception,
      message: "#{m.__struct__} Generate Identifier with ref type not supported"
  end

  # ----------------
  #
  # ----------------
  #def kind(m, R.ref(module: m)), do: {:ok, m}
  def kind(m, R.ref(module: _)), do: {:ok, m}
  def kind(m, %{__struct__: m}), do: {:ok, m}

  def kind(m, "ref." <> _ = ref) do
    # @TODO - verify ref.<is_sref>.{ref}
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- (sref && {:ok, sref}) || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          {:ok, m}

        :else ->
          {:error, {:unsupported, {__MODULE__, :kind, ref}}}
      end
    end
  end

  def kind(_m, ref), do: {:error, {:unsupported, {__MODULE__, :kind, ref}}}

  def id(m, R.ref(module: n, id: _) = ref) when m != n, do: {:ok, ref}

  def id(m, R.ref(module: m, id: R.ref(module: _, id: _)) = ref),
    do: {:ok, R.ref(ref, :id)}

  def id(m, %{__struct__: m, id: R.ref(module: _, id: _)} = ref),
    do: {:ok, ref.id}

  def id(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- (sref && {:ok, sref}) || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          inner_sref = String.trim_leading(ref, "ref.#{sref}.")

          with {:ok, inner_ref} <- Noizu.EntityReference.Protocol.ref(inner_sref) do
            {:ok, inner_ref}
          else
            _ -> {:error, {:unsupported, {__MODULE__, :id, ref}}}
          end

        :else ->
          {:error, {:unsupported, {__MODULE__, :id, ref}}}
      end
    end
  end

  def id(_m, ref), do: {:error, {:unsupported, {__MODULE__, :id, ref}}}

  def ref(m, R.ref(module: n, id: _) = inner_ref) when m != n,
    do: {:ok, R.ref(module: m, id: inner_ref)}

  def ref(m, R.ref(module: m, id: R.ref(module: _, id: _)) = ref), do: {:ok, ref}

  def ref(m, %{__struct__: m, id: R.ref(module: _, id: _)} = ref),
    do: {:ok, R.ref(module: m, id: ref.id)}

  def ref(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- (sref && {:ok, sref}) || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          inner_sref = String.trim_leading(ref, "ref.#{sref}.")

          with {:ok, inner_ref} <- Noizu.EntityReference.Protocol.ref(inner_sref) do
            {:ok, R.ref(module: m, id: inner_ref)}
          else
            _ -> {:error, {:unsupported, {__MODULE__, :ref, ref}}}
          end

        :else ->
          {:error, {:unsupported, {__MODULE__, :ref, ref}}}
      end
    end
  end

  def ref(_m, ref), do: {:error, {:unsupported, {__MODULE__, :ref, ref}}}

  def sref(m, ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- (sref && {:ok, sref}) || {:error, {:sref_undefined, m}},
         {:ok, inner_ref} <- apply(m, :id, [ref]),
         {:ok, inner_sref} <- Noizu.EntityReference.Protocol.sref(inner_ref) do
      {:ok, "ref.#{sref}.{#{inner_sref}}"}
    else
      _ -> {:error, {:unsupported, {__MODULE__, :sref, ref}}}
    end
  end

  def entity(m, %{__struct__: m} = ref, _context) do
    {:ok, ref}
  end

  def entity(m, ref, context) do
    with {:ok, ref} <- apply(m, :ref, [ref]),
         repo <- Noizu.Entity.Meta.repo(ref),
         {:ok, repo} <- (repo && {:ok, repo}) || {:error, {m, :repo_not_foundf}} do
      apply(repo, :get, [ref, context, []])
    else
      _ -> {:error, {:unsupported, {__MODULE__, :entity, ref}}}
    end
  end
end
