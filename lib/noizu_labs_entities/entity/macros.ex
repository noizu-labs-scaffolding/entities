#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity.Macros do
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL
  require Noizu.Entity.Meta.Persistence

  require Noizu.Entity.Macros.Json
  require Noizu.Entity.Macros.ACL

  #----------------------------------------
  # def_entity
  #----------------------------------------
  defmacro def_entity(do: block) do
    quote do
      import Noizu.Entity.Macros,
             only: [
               {:identifier, 1}, {:identifier, 2},
               {:field, 1}, {:field, 2}, {:field, 3},
               {:transient, 1},
               {:pii, 1}, {:pii, 2}
             ]
      require Noizu.Entity.Meta.Identifier
      require Noizu.Entity.Meta.Field
      require Noizu.Entity.Meta.Json
      require Noizu.Entity.Meta.ACL
      require Noizu.Entity.Meta.Persistence
      require Noizu.Entity.Macros.Json
      require Noizu.Entity.Macros.ACL


      Noizu.Entity.Macros.register_attributes(__MODULE__)

      # Persistence
      Noizu.Entity.Macros.extract_persistence()

      # Repo
      Noizu.Entity.Macros.extract_repo()

      # Sref
      Noizu.Entity.Macros.extract_sref()

      # Set Fields
      unquote(block)

      #--------------------------
      # Default Fields
      #--------------------------
      declared = Module.get_attribute(__MODULE__, :__nz_fields, [])
      unless Noizu.Entity.Macros.field_set?(:vsn, declared) do
        field :vsn, Module.get_attribute(__MODULE__, :vsn, 1.0)
      end
      unless Noizu.Entity.Macros.field_set?(:meta, declared) do
        field :meta, nil
      end
      unless Noizu.Entity.Macros.field_set?(:__transient__, declared) do
        @transient true
        field :__transient__, nil
      end

      #--------------------------
      # Emit Struct
      #--------------------------
      @derive Noizu.EntityReference.Protocol
      Module.get_attribute(__MODULE__, :__nz_fields, [])
      |> Noizu.Entity.Macros.prepare_struct()
      |> defstruct

      #--------------------------
      # Noizu.Entity Behavior
      #--------------------------
      {vsn, nz_meta} = Noizu.Entity.Macros.inject_entity_impl(
        @__nz_identifiers,
        @__nz_persistence,
        @__nz_fields,
        @__nz_json,
        @__nz_acl,
        @__nz_repo,
        @__nz_sref
      )
      @vsn vsn
      @nz_meta nz_meta
      def vsn(), do: @vsn
      def __noizu_meta__(), do: @nz_meta



      # ERP Hooks
      Noizu.Entity.Macros.erp(@__nz_identifiers)

    end
  end


  #----------------------------------------
  #
  #----------------------------------------
  defmacro extract_simple(attribute, attribute_default, default \\ false) do
    quote bind_quoted: [attribute: attribute, attribute_default: attribute_default, default: default] do
      case Module.get_attribute(__MODULE__, attribute, {:attribute, :blank}) do
        {:attribute, :blank} ->
          Module.get_attribute(__MODULE__, attribute_default, default)
        x ->
          Module.delete_attribute(__MODULE__, attribute)
          x
      end
    end
  end


  #==========================================================
  # def_entity macros
  #==========================================================

  @doc """
  Todo support different identifier types
  """
  defmacro erp(identifiers) do
    quote do
      require Noizu.Entity.Meta
      require Noizu.Entity.Meta.Identifier
      alias Noizu.Entity.Meta, as: Meta

      case unquote(identifiers) do
        [{:identifier, Meta.Identifier.identifier_settings(type: :integer)}] ->
          def kind(ref), do: Noizu.Entity.Meta.IntegerIdentifier.kind(__MODULE__, ref)
          def id(ref), do: Noizu.Entity.Meta.IntegerIdentifier.id(__MODULE__, ref)
          def ref(ref), do: Noizu.Entity.Meta.IntegerIdentifier.ref(__MODULE__, ref)
          def sref(ref), do: Noizu.Entity.Meta.IntegerIdentifier.sref(__MODULE__, ref)
          def entity(ref, context), do: Noizu.Entity.Meta.IntegerIdentifier.entity(__MODULE__, ref, context)
          def stub(), do: {:ok, %__MODULE__{}}
          def stub(ref, _context, _options) do
            with {:ok, id} <- apply(__MODULE__, :id, [ref]) do
              {:ok, %__MODULE__{identifier: id}}
            end
          end
        [{:identifier, Meta.Identifier.identifier_settings(type: :ref)}] ->
          def kind(ref), do: Noizu.Entity.Meta.RefIdentifier.kind(__MODULE__, ref)
          def id(ref), do: Noizu.Entity.Meta.RefIdentifier.id(__MODULE__, ref)
          def ref(ref), do: Noizu.Entity.Meta.RefIdentifier.ref(__MODULE__, ref)
          def sref(ref), do: Noizu.Entity.Meta.RefIdentifier.sref(__MODULE__, ref)
          def entity(ref, context), do: Noizu.Entity.Meta.RefIdentifier.entity(__MODULE__, ref, context)
          def stub(), do: {:ok, %__MODULE__{}}
          def stub(ref, _context, _options) do
            with {:ok, id} <- apply(__MODULE__, :id, [ref]) do
              {:ok, %__MODULE__{identifier: id}}
            end
          end
        [{:identifier, Meta.Identifier.identifier_settings(type: :dual_ref)}] ->
          def kind(ref), do: Noizu.Entity.Meta.DualRefIdentifier.kind(__MODULE__, ref)
          def id(ref), do: Noizu.Entity.Meta.DualRefIdentifier.id(__MODULE__, ref)
          def ref(ref), do: Noizu.Entity.Meta.DualRefIdentifier.ref(__MODULE__, ref)
          def sref(ref), do: Noizu.Entity.Meta.DualRefIdentifier.sref(__MODULE__, ref)
          def entity(ref, context), do: Noizu.Entity.Meta.DualRefIdentifier.entity(__MODULE__, ref, context)
          def stub(), do: {:ok, %__MODULE__{}}
          def stub(ref, _context, _options) do
            with {:ok, id} <- apply(__MODULE__, :id, [ref]) do
              {:ok, %__MODULE__{identifier: id}}
            end
          end

        [{:identifier, Meta.Identifier.identifier_settings(type: :uuid)}] ->
          def kind(ref), do: Noizu.Entity.Meta.UUIDIdentifier.kind(__MODULE__, ref)
          def id(ref), do: Noizu.Entity.Meta.UUIDIdentifier.id(__MODULE__, ref)
          def ref(ref), do: Noizu.Entity.Meta.UUIDIdentifier.ref(__MODULE__, ref)
          def sref(ref), do: Noizu.Entity.Meta.UUIDIdentifier.sref(__MODULE__, ref)
          def entity(ref, context), do: Noizu.Entity.Meta.UUIDIdentifier.entity(__MODULE__, ref, context)
          def stub(), do: {:ok, %__MODULE__{}}
          def stub(ref, _context, _options) do
            with {:ok, id} <- apply(__MODULE__, :id, [ref]) do
              {:ok, %__MODULE__{identifier: id}}
            end
          end

        [{:identifier, Meta.Identifier.identifier_settings(type: user_provided)}] ->
          def kind(ref), do: apply(user_provided, :kind, [__MODULE__, ref])
          def id(ref), do: apply(user_provided, :id, [__MODULE__, ref])
          def ref(ref), do: apply(user_provided, :ref, [__MODULE__, ref])
          def sref(ref), do: apply(user_provided, :sref, [__MODULE__, ref])
          def entity(ref, context), do: apply(user_provided, :entity, [__MODULE__, ref, context])
          def stub(), do: {:ok, %__MODULE__{}}
          def stub(ref, _context, _options) do
            with {:ok, id} <- apply(__MODULE__, :id, [ref]) do
              {:ok, %__MODULE__{identifier: id}}
            end
          end
      end


      defoverridable [
        kind: 1,
        id: 1,
        ref: 1,
        sref: 1,
        entity: 2,
        stub: 0,
        stub: 3,
      ]
    end
  end


  defmacro common() do
    quote do
      def id(_), do: :nyi
    end
  end


  #----------------------------------------
  # identifier
  #----------------------------------------
  defmacro identifier(type, opts \\ []) do
    name = opts[:name] || :identifier
    quote do
      Module.put_attribute(__MODULE__, :__nz_identifiers, {unquote(name), Noizu.Entity.Meta.Identifier.identifier_settings(name: unquote(name), type: unquote(type))})
      Module.put_attribute(__MODULE__, :__nz_fields, {unquote(name), Noizu.Entity.Meta.Field.field_settings(name: unquote(name), default: nil)})
    end
  end

  #----------------------------------------
  # field
  #----------------------------------------
  defmacro field(name, default \\ nil, type \\ nil, _opts \\ []) do
    quote bind_quoted: [name: name, type: type, default: default] do
      Noizu.Entity.Macros.Json.extract_json(name)
      acl = {field, field_acl} = Noizu.Entity.Macros.ACL.extract_acl(name)
      Module.put_attribute(__MODULE__, :__nz_acl, acl)

      # Extract any storage attributes.
      store = case Noizu.Entity.Macros.extract_simple(:store, :store_default, []) do
        v when is_list(v) ->
          Enum.map(v,
            fn
              ({store,settings}) -> {store, settings}
              (settings) ->
                case @__nz_persistence do
                  [store|_] ->
                    Noizu.Entity.Meta.Persistence.persistence_settings(store: store) = store
                    {store, settings}
                end
            end
          )
        _ -> nil
      end

      Module.put_attribute(
        __MODULE__,
        :__nz_fields,
        {
          name,
          Noizu.Entity.Meta.Field.field_settings(
            name: name,
            default: default,
            store: store,
            type: type,
            pii: Noizu.Entity.Macros.extract_simple(:pii, :pii_default),
            transient: Noizu.Entity.Macros.extract_simple(:transient, :transient_default),
            acl: field_acl
          )
        }
      )
    end
  end

  #----------------------------------------
  # transient
  #----------------------------------------
  defmacro transient(do: block) do
    quote do
      Noizu.Entity.Macros.push_attribute_queue(__MODULE__, :transient_default, :transient_default_queue, true)
      unquote(block)
      Noizu.Entity.Macros.pop_attribute_queue(__MODULE__, :transient_default, :transient_default_queue)
    end
  end

  #----------------------------------------
  # pii
  #----------------------------------------
  defmacro pii(level \\ :sensitive, do: block) do
    quote do
      Noizu.Entity.Macros.push_attribute_queue(__MODULE__, :pii_default, :pii_default_queue, unquote(level))
      unquote(block)
      Noizu.Entity.Macros.pop_attribute_queue(__MODULE__, :pii_default, :pii_default_queue)
    end
  end

  #==========================================================
  # internal macros
  #==========================================================

  #----------------------------------------
  #
  #----------------------------------------
  def push_attribute_queue(module, a_d, a_d_q, value) do
    q = [value| Module.get_attribute(module, a_d_q, [])]
    Module.put_attribute(module, a_d_q, q)
    Module.put_attribute(module, a_d, value)
  end

  #----------------------------------------
  #
  #----------------------------------------
  def pop_attribute_queue(module, a_d, a_d_q) do
    with [_|t] <- Module.get_attribute(module, a_d_q, []) do
      Module.put_attribute(module, a_d_q, t)
      with [h|_] <- t do
        Module.put_attribute(module, a_d, h)
      else
        _ ->
          Module.delete_attribute(module, a_d)
      end
    else
    _ ->
      # invalid
      Module.delete_attribute(module, a_d_q)
      Module.delete_attribute(module, a_d)
    end
  end


  #----------------------------------------
  #
  #----------------------------------------
  defmacro extract_persistence() do
    quote do
      case Noizu.Entity.Macros.extract_simple(:persistence, :persistence, []) do
        v when is_list(v) ->
          layers = Enum.map(v,
                     fn(x) ->
                       case x do
                         Noizu.Entity.Meta.Persistence.persistence_settings(kind: nil) ->
                           Noizu.Entity.Meta.Persistence.persistence_settings(x, kind: __MODULE__)
                         Noizu.Entity.Meta.Persistence.persistence_settings() -> x
                         _ -> nil
                       end
                     end)
                   |> Enum.filter(&(&1))
          Module.put_attribute(__MODULE__, :__nz_persistence, layers)
        _ ->
          Module.put_attribute(__MODULE__, :__nz_persistence, [])
      end
    end
  end

  #----------------------------------------
  #
  #----------------------------------------
  defmacro extract_repo() do
    quote do
      case Noizu.Entity.Macros.extract_simple(:repo, :repo, []) do
        v when is_atom(v) ->
          Module.put_attribute(__MODULE__, :__nz_repo, v)
        _ ->
          Module.put_attribute(__MODULE__, :__nz_repo, Module.concat([__MODULE__, Repo]))
      end
    end
  end

  #----------------------------------------
  #
  #----------------------------------------
  defmacro extract_sref() do
    quote do
      case Noizu.Entity.Macros.extract_simple(:sref, :sref, nil) do
        v when is_bitstring(v) ->
          Module.put_attribute(__MODULE__, :__nz_sref, v)
        _ ->
          Module.put_attribute(__MODULE__, :__nz_sref, nil)
      end
    end
  end

  #----------------------------------------
  #
  #----------------------------------------
  def register_attributes(mod) do
    Module.register_attribute(mod, :__nz_identifiers, accumulate: true)
    Module.register_attribute(mod, :__nz_fields, accumulate: true)
    Module.register_attribute(mod, :__nz_persistence, accumulate: false)
    Module.register_attribute(mod, :__nz_repo, accumulate: false)
    Module.register_attribute(mod, :__nz_sref, accumulate: false)
    Module.register_attribute(mod, :store, accumulate: true)
    Noizu.Entity.Macros.Json.register_attributes(mod)
    Noizu.Entity.Macros.ACL.register_attributes(mod)
  end

  #----------------------------------------
  #
  #----------------------------------------
  def field_set?(field, declared_fields) do
    get_in(declared_fields, [field])
  end

  #----------------------------------------
  #
  #----------------------------------------
  def prepare_struct(fields) do
    fields
    |> Enum.map(fn({name, Noizu.Entity.Meta.Field.field_settings(default: dv)}) -> {name, dv} end)
    |> Enum.reverse()
  end

  #----------------------------------------
  #
  #----------------------------------------
  def inject_entity_impl(v__nz_identifiers, v__nz_persistence, v__nz_fields, v__nz_json, v__nz_acl, v__nz_repo, v__nz_sref) do
    #v__nz_fields = Module.get_attribute(module, :__nz_fields, [])
    Noizu.Entity.Meta.Field.field_settings(default: vsn) = get_in(v__nz_fields, [:vsn])
    #Module.put_attribute(module, :vsn, vsn)

    # __noizu_meta__\0
    nz_entity__persistence = Enum.reverse(v__nz_persistence)
    nz_entity__fields = Enum.reverse(v__nz_fields)
    #v__nz_identifiers = Module.get_attribute(module, :__nz_identifiers, [])
    nz_entity__identifier = (case(v__nz_identifiers) do
                               [x] -> x
                               x -> Enum.reverse(x)
                             end)
    # (Module.get_attribute(module, :__nz_json, [])
    nz_entity__json = v__nz_json
                      |> Noizu.Entity.Macros.Json.expand_json_settings(nz_entity__fields)


    # todo this should be done in function close.
    acl = Enum.map(v__nz_acl,
      fn
        ({field, [nz: :inherit]}) ->
          with Noizu.Entity.Meta.Field.field_settings(transient: t, pii: p) <- nz_entity__fields[field] do
            x = cond do
              t ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :role, requirement: [:admin, :system])
              p in [:sensitive, :private] ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :role, requirement: [:user, :admin, :system])
              :else ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :unrestricted, requirement: :unrestricted)
            end
            {field, x}
          end
        ({field, x}) -> {field, x}
    end)

    nz_meta = %{
      identifier: nz_entity__identifier,
      fields: nz_entity__fields,
      json: nz_entity__json,
      persistence: nz_entity__persistence,
      acl: acl,
      repo: v__nz_repo,
      sref: v__nz_sref
    }
    #Module.put_attribute(module, :nz_meta, nz_meta)
    {vsn, nz_meta}
  end

end
