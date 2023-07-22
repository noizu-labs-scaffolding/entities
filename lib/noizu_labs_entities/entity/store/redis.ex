#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Redis.Protocol do
  @fallback_to_any true

  def as_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
  def persist(entity, type, settings, context, options)
end

defimpl Noizu.Entity.Store.Redis.Protocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence

  def persist(_entity, _type, _settings, _context, _options) do
    {:error, :pending}
  end

  def as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(table: _table), _context, _options) do
    # @todo strip transient fields,
    # @todo collapse refs.
    # @todo map fields
    # @todo Inject indexes
    {:ok, entity}
  end

  def from_record(nil, _, _context, _options) do
    {:error, :not_found}
  end
  def from_record(record, _, _context, _options) do
    {:ok, record}
  end
end
