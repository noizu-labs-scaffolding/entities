# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Amnesia.EntityProtocol do
  @fallback_to_any true

  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def as_entity(entity, settings, context, options)
  def as_entity(entity, record, settings, context, options)
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
  def from_record(entity, record, settings, context, options)
end

defprotocol Noizu.Entity.Store.Amnesia.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end

defimpl Noizu.Entity.Store.Amnesia.EntityProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence

  # ---------------------------
  #
  # ---------------------------
  def persist(_entity, _type, _settings, _context, _options) do
    {:error, :pending}
  end

  # ---------------------------
  #
  # ---------------------------
  def as_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        _context,
        _options
      ) do
    # todo strip transient fields,
    # collapse refs.

    # @todo Inject indexes
    indexes_and_entity = [entity: entity]
    record = struct(table, indexes_and_entity)
    {:ok, record}
  end

  # ---------------------------
  #
  # ---------------------------
  def as_entity(
        entity,
        settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        context,
        options
      ) do
    with {:ok, identifier} <- Noizu.EntityReference.Protocol.id(entity),
         record <- apply(table, :get!, identifier) do
      from_record(record, settings, context, options)
    end
  end

  # ---------------------------
  #
  # ---------------------------
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
  def delete_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        _context,
        _options
      ) do
    with {:ok, identifier} <- Noizu.EntityReference.Protocol.id(entity) do
      apply(table, :delete!, identifier)
    end
  end

  # ---------------------------
  #
  # ---------------------------
  def from_record(%{entity: entity}, _settings, _context, _options) do
    {:ok, entity}
  end

  def from_record(_, record, settings, context, options) do
    # @todo refresh entity with record
    from_record(record, settings, context, options)
  end

  def from_record(_, _settings, _context, _options) do
    {:error, :invalid_record}
  end
end

defimpl Noizu.Entity.Store.Amnesia.Entity.FieldProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence

  def field_as_record(_field, _field_settings, _persistence_settings, _context, _options),
    do: {:error, {:unsupported, Amnesia}}

  def field_from_record(
        _field,
        _record,
        _field_settings,
        _persistence_settings,
        _context,
        _options
      ),
      do: {:error, {:unsupported, Amnesia}}
end
