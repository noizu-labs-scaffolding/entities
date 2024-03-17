# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entity.Store.Ecto.Exception do
  defexception [:message]
end

defprotocol Noizu.Entity.Store.Ecto.EntityProtocol do
  @fallback_to_any true
  require Noizu.Entity.Meta.Field

  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def as_entity(entity, settings, context, options)
  def as_entity(entity, record, settings, context, options)
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
  def from_record(entity, record, settings, context, options)
end

defprotocol Noizu.Entity.Store.Ecto.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end

unless Code.ensure_loaded?(Ecto) do
  defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Any] do
    def persist(entity, type, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def as_record(entity, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def as_entity(entity, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def as_entity(entity, record, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def delete_record(entity, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def from_record(record, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def from_record(entity, record, settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")
  end

  defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Any] do
    def field_as_record(field, field_settings, persistence_settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")

    def field_from_record(field, record, field_settings, persistence_settings, context, options),
        do: raise(Noizu.Entity.Store.Ecto.Exception, message: "Ecto Not Available")
  end
else
  defmodule Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour do
    require Noizu.Entity.Meta.Persistence
    require Noizu.Entity.Meta.Field

    # ---------------------------
    #
    # ---------------------------
    @callback persist(
                record :: any,
                type :: :create | :update,
                settings :: Tuple,
                context :: any,
                options :: any
              ) :: {:ok, any} | {:error, details :: any}
    def persist(
          %{__struct__: table} = record,
          :create,
          Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: repo),
          _context,
          _options
        ) do
      # Verify table match
      apply(repo, :insert, [record])
    end

    def persist(
          %{__struct__: table} = record,
          :update,
          Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: repo),
          _context,
          _options
        ) do
      # 1. Get record
      if current = apply(repo, :get, [table, record.id]) do
        cs = apply(table, :changeset, [current, Map.from_struct(record)])
        apply(repo, :update, [cs])
      end
    end

    def persist(_, _, _, _, _) do
      {:error, :pending}
    end

    # ---------------------------
    #
    # ---------------------------
    @callback as_record(entity :: any, settings :: Tuple, context :: any, options :: any) ::
                {:ok, any} | {:error, details :: any}
    def as_record(
          entity,
          Noizu.Entity.Meta.Persistence.persistence_settings(table: table) = settings,
          context,
          options
        ) do
      # @todo strip transient fields,
      # @todo collapse refs.
      # @todo map fields
      # @todo Inject indexes

      #     Record.defrecord(:field_settings, [name: nil, store: nil, type: nil, transient: false, pii: false, default: nil, acl: nil])
      fields =
        Noizu.Entity.Meta.fields(entity) |> IO.inspect(label: "AS_RECORD")
        |> Enum.map(fn
          {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: nil) = field_settings} ->
            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_as_record(
              get_in(entity, [Access.key(name)]),
              field_settings,
              settings,
              context,
              options
            )
          {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: {:ecto, _}) = field_settings} ->
            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_as_record(
              get_in(entity, [Access.key(name)]),
              field_settings,
              settings,
              context,
              options
            )

          {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: type) = field_settings} ->
            {:ok, field_entry} =
              apply(type, :type_as_entity, [get_in(entity, [Access.key(name)]), context, options])


            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_as_record(
              field_entry,
              field_settings,
              settings,
              context,
              options
            )
        end)
        |> List.flatten()
        |> List.flatten()
        |> Enum.map(fn
          {:ok, v} -> v
          _ -> nil
        end)
        |> Enum.filter(& &1)



      record = struct(table, fields)
      {:ok, record}
    end

    # ---------------------------
    #
    # ---------------------------
    @callback as_entity(entity :: any, settings :: Tuple, context :: any, options :: any) ::
                {:ok, any} | {:error, details :: any}
    def as_entity(
          entity,
          settings =
            Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: store),
          context,
          options
        ) do
      with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity),
           record = %{} <- apply(store, :get, [table, id]) do
        from_record(record, settings, context, options)
      end
    end

    # ---------------------------
    #
    # ---------------------------
    @callback as_entity(
                entity :: any,
                record :: any,
                settings :: Tuple,
                context :: any,
                options :: any
              ) :: {:ok, any} | {:error, details :: any}
    def as_entity(
          _,
          record,
          settings = Noizu.Entity.Meta.Persistence.persistence_settings(),
          context,
          options
        ) do
      from_record(record, settings, context, options)
    end

    # ---------------------------
    #
    # ---------------------------
    @callback delete_record(entity :: any, settings :: Tuple, context :: any, options :: any) ::
                {:ok, any} | {:error, details :: any}
    def delete_record(
          entity,
          Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: store),
          _context,
          _options
        ) do
      with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity) do
        apply(store, :delete, [struct(table, id: id)])
      end
    end

    # ---------------------------
    #
    # ---------------------------
    @callback from_record(
                entity :: any,
                record :: any,
                settings :: Tuple,
                context :: any,
                options :: any
              ) :: {:ok, any} | {:error, details :: any}
    def from_record(
          _entity,
          record,
          Noizu.Entity.Meta.Persistence.persistence_settings(kind: _kind) = settings,
          context,
          options
        ) do
      from_record(record, settings, context, options)
    end

    @callback from_record(entity :: any, settings :: Tuple, context :: any, options :: any) ::
                {:ok, any} | {:error, details :: any}
    def from_record(
          record,
          Noizu.Entity.Meta.Persistence.persistence_settings(kind: kind) = settings,
          context,
          options
        ) do
      fields =
        Noizu.Entity.Meta.fields(kind)
        |> Enum.map(fn
          {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: nil) = field_settings} ->
            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_from_record(
              nil,
              record,
              field_settings,
              settings,
              context,
              options
            )
          {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: {:ecto, _}) = field_settings} ->
            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_from_record(
              nil,
              record,
              field_settings,
              settings,
              context,
              options
            )
          {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: type) = field_settings} ->
            {:ok, stub} = apply(type, :stub, [])

            Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_from_record(
              # used for matching
              stub,
              record,
              field_settings,
              settings,
              context,
              options
            )
        end)
        |> List.flatten()
        |> Enum.map(fn
          {:ok, v} -> v
          _ -> nil
        end)
        |> Enum.filter(& &1)

      entity = struct(kind, fields)
      {:ok, entity}
    end

    defmacro __using__(_) do
      quote do
        @behaviour Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour
        defdelegate persist(record, action, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate as_record(record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate as_entity(record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate as_entity(entity, record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate delete_record(record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate from_record(record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defdelegate from_record(entity, record, settings, context, options),
                    to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defoverridable persist: 5,
                       as_record: 4,
                       as_entity: 4,
                       as_entity: 5,
                       delete_record: 4,
                       from_record: 4,
                       from_record: 5
      end
    end
  end

  defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Any] do
    defmacro __deriving__(module, _struct, _options) do
      quote do
        use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

        defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [unquote(module)] do
          def persist(record, action, settings, context, options),
              do: apply(unquote(module), :persist, [record, action, settings, context, options])

          def as_record(record, settings, context, options),
              do: apply(unquote(module), :as_record, [record, settings, context, options])

          def as_entity(record, settings, context, options),
              do: apply(unquote(module), :as_entity, [record, settings, context, options])

          def as_entity(entity, record, settings, context, options),
              do: apply(unquote(module), :as_entity, [entity, record, settings, context, options])

          def delete_record(record, settings, context, options),
              do: apply(unquote(module), :delete_record, [record, settings, context, options])

          def from_record(record, settings, context, options),
              do: apply(unquote(module), :from_record, [record, settings, context, options])

          def from_record(entity, record, settings, context, options),
              do: apply(unquote(module), :from_record, [entity, record, settings, context, options])
        end
      end
    end

    defdelegate persist(record, action, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate as_record(record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate as_entity(record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate as_entity(entity, record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate delete_record(record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate from_record(record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

    defdelegate from_record(entity, record, settings, context, options),
                to: Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour
  end

  defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Any] do
    require Noizu.Entity.Meta.Persistence
    require Noizu.Entity.Meta.Field

    # ---------------------------
    #
    # ---------------------------
    def field_as_record(
          field,
          Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
          Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
          _context,
          _options
        ) do
      name = field_store[table][:name] || field_store[store][:name] || name
      {:ok, {name, field}}
    end

    # ---------------------------
    #
    # ---------------------------
    def field_from_record(
          _field_stub,
          record,
          Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
          Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
          _context,
          _options
        ) do
      as_name = field_store[table][:name] || field_store[store][:name] || name
      {:ok, {name, get_in(record, [Access.key(as_name)])}}
    end
  end
end
