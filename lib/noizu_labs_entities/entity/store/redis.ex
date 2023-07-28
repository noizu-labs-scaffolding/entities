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
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
  def key(entity, settings, context, options)
end

defprotocol Noizu.Entity.Store.Redis.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end


defimpl Noizu.Entity.Store.Redis.EntityProtocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence


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
  def from_record(nil, _, _context, _options) do
    {:error, :not_found}
  end


  #---------------------------
  #
  #---------------------------
  def from_record(record, _, _context, _options) do
    {:ok, record}
  end
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
