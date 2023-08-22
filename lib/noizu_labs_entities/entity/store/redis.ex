#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Redis.EntityProtocol do
  @fallback_to_any true
  require  Noizu.Entity.Meta.Field

  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def as_entity(entity, settings, context, options)
  def as_entity(entity, record, settings, context, options)
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
  def from_record(entity, record, settings, context, options)
  def key(entity, settings, context, options)
end

defprotocol Noizu.Entity.Store.Redis.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end


defmodule Noizu.Entity.Store.Redis.EntityProtocol.Behaviour do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  #---------------------------
  #
  #---------------------------
  def key(entity, _settings, _context, _options) do
    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(entity) do
      key = "#{sref}.redis_store"
      {:ok, key}
    end
  end


  #---------------------------
  #
  #---------------------------
  def persist(entity, _type, settings = Noizu.Entity.Meta.Persistence.persistence_settings(store: store), context, options) do
    with {:ok, key} <- key(entity, settings, context, options),
         {:ok, redis_entity} <- as_record(entity, settings, context, options) do
      apply(store, :set_binary, [key, redis_entity])
      {:ok, entity}
    end
  end


  #---------------------------
  #
  #---------------------------
  def as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(table: _table), _context, _options) do
    # @todo strip transient fields,
    # @todo collapse refs.
    # @todo map fields
    # @todo Inject indexes
    {:ok, entity}
  end


  #---------------------------
  #
  #---------------------------
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(store: store), context, options) do
    with {:ok, key} <- key(entity, settings, context, options),
         {:ok, redis_entity} <- apply(store, :get_binary, [key]),
         true <- redis_entity && true || {:error, :not_found},
         {:ok, entity} <- from_record(redis_entity, settings, context, options)
      do
      {:ok, entity}
    end
  end

  #---------------------------
  #
  #---------------------------
  def as_entity(_, record, settings = Noizu.Entity.Meta.Persistence.persistence_settings(), context, options) do
    from_record(record, settings, context, options)
  end

  #---------------------------
  #
  #---------------------------
  def delete_record(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(store: store), context, options) do
    with {:ok, key} <- key(entity, settings, context, options),
         :ok <- apply(store, :delete, [key])
      do
      {:ok, entity}
    end
  end


  #---------------------------
  #
  #---------------------------
  def from_record(_, record, settings, context, options) do
    # todo refresh entity
    from_record(record, settings, context, options)
  end

  #---------------------------
  #
  #---------------------------
  def from_record(nil, _, _context, _options) do
    {:error, :not_found}
  end

  #---------------------------
  #
  #---------------------------
  def from_record(record, _, _context, _options) do
    {:ok, record}
  end

  defmacro __using__(_) do
    quote do
      @behaviour Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate key(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate persist(record, action, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate as_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate as_entity(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate as_entity(entity, record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate delete_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate from_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate from_record(entity, record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defoverridable [
        key: 4,
        persist: 5,
        as_record: 4,
        as_entity: 4,
        as_entity: 5,
        delete_record: 4,
        from_record: 4,
        from_record: 5
      ]
    end
  end
end


defimpl Noizu.Entity.Store.Redis.EntityProtocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence

  defmacro __deriving__(module, struct, options) do
    quote do
      use Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defimpl Noizu.Entity.Store.Redis.EntityProtocol, for: [unquote(module)] do
        def key(record, settings, context, options), do: apply(unquote(module), :key, [record, settings, context, options])
        def persist(record, action, settings, context, options), do: apply(unquote(module), :persist, [record, action, settings, context, options])
        def as_record(record, settings, context, options), do: apply(unquote(module), :as_record, [record, settings, context, options])
        def as_entity(record, settings, context, options), do: apply(unquote(module), :as_entity, [record, settings, context, options])
        def as_entity(entity, record, settings, context, options), do: apply(unquote(module), :as_entity, [entity, record, settings, context, options])
        def delete_record(record, settings, context, options), do: apply(unquote(module), :delete_record, [record, settings, context, options])
        def from_record(record, settings, context, options), do: apply(unquote(module), :from_record, [record, settings, context, options])
        def from_record(entity, record, settings, context, options), do: apply(unquote(module), :from_record, [entity, record, settings, context, options])
      end
    end
  end

  defdelegate persist(record, action, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate as_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate as_entity(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate as_entity(entity, record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate delete_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate from_record(record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
  defdelegate from_record(entity, record, settings, context, options), to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

end

defimpl Noizu.Entity.Store.Redis.Entity.FieldProtocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field
  #---------------------------
  #
  #---------------------------
  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: _field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: _store, table: _table),
        _context,
        _options
      ) do
    {:ok, {name, field}}
  end

  #---------------------------
  #
  #---------------------------
  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: _field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: _store, table: _table),
        _context,
        _options
      ) do
    {:ok, {name, get_in(record, [Access.key(name)])}}
  end
end
