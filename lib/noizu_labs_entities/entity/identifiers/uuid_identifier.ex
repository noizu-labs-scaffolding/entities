
#================================
# ERP methods
#================================

unless Code.ensure_loaded?(UUID) do

defmodule Noizu.Entity.Meta.UUIDIdentifier do
    require Noizu.EntityReference.Records
    alias Noizu.EntityReference.Records, as: R

    #----------------
    #
    #----------------
    def format_identifier(_,_,_), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

    def kind(_m, _id), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

    def id(_m, _id), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

    def ref(_m, _id), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

    def sref(_m, _id), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

    def entity(_m, _id, _context), do: (raise Noizu.Entity.Identifier.Exception, message: "UUID Not Available")

end

else

defmodule Noizu.Entity.Meta.UUIDIdentifier do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  def format_identifier(m, identifier, index) do
    with repo <- Noizu.Entity.Meta.repo(m) do
      <<e10,e11,e12>> = Integer.to_string(index, 16) |> String.pad_leading("0", 3)
      <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,_,_,_>> = UUID.uuid5(UUID.uuid5(:dns, "#{repo}"), "#{identifier}", :default)
      <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>
    end
  end

  def uuid_string(<<_::binary-size(16)>> = id), do: UUID.binary_to_string!(id)
  def uuid_string(<<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = id), do: id

  #----------------
  #
  #----------------
  def kind(m, <<_::binary-size(16)>> = _id), do: {:ok, m}
  def kind(m, <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = _id), do: {:ok, m}
  def kind(m, R.ref(module: m)), do: {:ok, m}
  def kind(m, %{__struct__: m}), do: {:ok, m}
  def kind(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          {:ok, m}
        :else -> {:error, {:unsupported, {__MODULE__, :kind, ref}}}
      end
    end
  end
  def kind(_m, ref), do: {:error, {:unsupported, {__MODULE__, :kind, ref}}}

  def id(m, <<_::binary-size(16)>> = id), do: {:ok, uuid_string(id)}
  def id(m, <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = id), do: {:ok, id}
  def id(m, R.ref(module: m, identifier: <<_::binary-size(16)>>) = ref), do: {:ok, R.ref(ref, :identifier) |> uuid_string()}
  def id(m, R.ref(module: m, identifier: <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>) = ref), do: {:ok, R.ref(ref, :identifier)}
  def id(m, R.ref(module: m, identifier: <<_::binary-size(16)>>) = ref), do: {:ok, R.ref(ref, :identifier) |> uuid_string()}
  def id(m, R.ref(module: m, identifier: <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>) = ref), do: {:ok, R.ref(ref, :identifier)}
  def id(m, %{__struct__: m, identifier: <<_::binary-size(16)>>} = ref), do: {:ok, ref.identifier |> uuid_string()}
  def id(m, %{__struct__: m, identifier: <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>} = ref), do: {:ok, ref.identifier}
  def id(m, "ref." <> _ = ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}} do
      cond do
        String.starts_with?(ref, "ref.#{sref}.") ->
          id = String.trim_leading(ref, "ref.#{sref}.")
          case id do
            v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> -> {:ok, v}
            _ -> {:error, {:unsupported, {__MODULE__, :id, ref}}}
          end
        :else -> {:error, {:unsupported, {__MODULE__, :id, ref}}}
      end
    end
  end
  def id(_m, ref), do: {:error, {:unsupported, {__MODULE__, :id, ref}}}


  def ref(m, ref) do
    with {:ok, id} <- apply(m, :id, [ref]) do
      {:ok, R.ref(module: m, identifier: id)}
    end
  end

  def sref(m, ref) do
    with sref <- Noizu.Entity.Meta.sref(m),
         {:ok, sref} <- sref && {:ok, sref} || {:error, {:sref_undefined, m}},
         {:ok, id} <- apply(m, :id, [ref]) do
      {:ok, "ref.#{sref}.#{id}"}
    end
  end


  def entity(m, %{__struct__: m, identifier: <<_::binary-size(16)>>} = ref, _context), do: {:ok, ref}
  def entity(m, %{__struct__: m, identifier: <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>} = ref, _context), do: {:ok, ref}
  def entity(m, ref, context) do
    with {:ok, ref} <- apply(m, :ref, [ref]),
         repo <- Noizu.Entity.Meta.repo(ref),
         {:ok, repo} <- repo && {:ok, repo} || {:error, {m, :repo_not_found}}
      do
      apply(repo, :get, [ref, context, []])
    end
  end

end

end
