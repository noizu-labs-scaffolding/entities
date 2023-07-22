#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defprotocol Noizu.Entity.Store.Mnesia.EntityProtocol do
  @fallback_to_any true
  require  Noizu.Entity.Meta.Field

  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def as_entity(entity, settings, context, options)
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
end

defprotocol Noizu.Entity.Store.Mnesia.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end
