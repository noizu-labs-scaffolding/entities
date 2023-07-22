#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.Entity.Meta do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  defmodule ACL do
    require Record
    Record.defrecord(:acl_settings, [target: nil, type: nil, requirement: nil])
  end
  defmodule Identifier do
    require Record
    Record.defrecord(:identifier_settings, [name: nil, generate: true, universal: false,  type: nil])
  end
  defmodule Field do
    require Record
    Record.defrecord(:field_settings, [name: nil, store: [], type: nil, transient: false, pii: false, default: nil, acl: nil])
  end
  defmodule Persistence do
    require Record
    Record.defrecord(:persistence_settings, [table: :auto, kind: nil, store: nil, type: nil])
    def ecto_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Ecto)
    end
    def mnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Mnesia)
    end
    def amnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Amnesia)
    end
    def redis_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Redis)
    end
  end
  defmodule Json do
    require Record
    Record.defrecord(:json_settings, [template: nil, field: nil, as: {:nz, :inherit}, omit: {:nz, :inherit}, error: {:nz, :inherit}])
    #Record.defrecord(:field_settings, [field: nil, settings: nil])
    #Record.defrecord(:template_field_settings, [template: nil, field_settings: nil])
  end

  @callback meta() :: []
  @callback fields() :: []
  @callback identifier() :: []
  @callback persistence() :: []
  @callback json() :: []
  @callback json(template :: atom) :: []


  #---------------
  #
  #---------------
  def meta(%{__struct__: m}), do: meta(m)
  def meta(R.ref(module: m)), do: meta(m)
  def meta(m) when is_atom(m), do: apply(m, :__noizu_meta__, [])
  def meta(m), do: raise Noizu.EntityReference.ProtocolException, ref: m, message: "Invalid Entity", error: :invalid


  #---------------
  #
  #---------------
  def sref(m), do: meta(m)[:sref]

  #---------------
  #
  #---------------
  def persistence(m), do: meta(m)[:persistence]


  #---------------
  #
  #---------------
  def repo(m), do: meta(m)[:repo]


  #---------------
  #
  #---------------
  def identifier(m), do: meta(m)[:identifier]


  #---------------
  #
  #---------------
  def fields(m), do: meta(m)[:fields]


  #---------------
  #
  #---------------
  def json(m), do: meta(m)[:json]


  #---------------
  #
  #---------------
  def json(m, s) do
    meta = meta(m)
    json = meta[:json]
    json[s] || json[:default]
  end


  #---------------
  #
  #---------------
  def acl(m), do: meta(m)[:acl]


  #================================
  # ERP methods
  #================================
  defmodule IntegerIdentifier do
    require Noizu.EntityReference.Records
    alias Noizu.EntityReference.Records, as: R

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

    def id(m, id) when is_integer(id), do: {:ok, m}
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

  #---------------
  #
  #---------------

  #---------------
  #
  #---------------
  defmacro __using__(_options \\ nil) do
    quote do
      require Noizu.Entity.Meta.Identifier
      require Noizu.Entity.Meta.Field
      require Noizu.Entity.Meta.Json
      alias Noizu.Entity.Meta
    end
  end

end
