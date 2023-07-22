#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Amnesia.Protocol do
  @fallback_to_any true
  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
end

defimpl Noizu.Entity.Store.Amnesia.Protocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence

  def persist(_entity, _type, _settings, _context, _options) do
    {:error, :pending}
  end

  def as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(table: table), _context, _options) do
    # todo strip transient fields,
    # collapse refs.

    # @todo Inject indexes
    indexes_and_entity = [entity: entity]
    record = struct(table, indexes_and_entity)
    {:ok, record}
  end

  def from_record(%{entity: entity}, _settings, _context, _options) do
    {:ok, entity}
  end
  def from_record(_, _settings, _context, _options) do
    {:error, :invalid_record}
  end

end
