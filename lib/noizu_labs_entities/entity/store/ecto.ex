#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defprotocol Noizu.Entity.Store.Ecto.EntityProtocol do
  @fallback_to_any true
  require  Noizu.Entity.Meta.Field

  def persist(entity, type, settings, context, options)
  def as_record(entity, settings, context, options)
  def as_entity(entity, settings, context, options)
  def delete_record(entity, settings, context, options)
  def from_record(record, settings, context, options)
end

defprotocol Noizu.Entity.Store.Ecto.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  #---------------------------
  #
  #---------------------------
  def persist(%{__struct__: table} = record, :create,  Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: repo), _context, _options) do
    # Verify table match
    apply(repo, :insert, [record])
  end
  def persist(%{__struct__: table} = record, :update,  Noizu.Entity.Meta.Persistence.persistence_settings(table: table, store: repo), _context, _options) do
    # 1. Get record
    if current = apply(repo, :get, [table, record.identifier]) do
      cs = apply(table, :changeset, [current, Map.from_struct(record)])
      apply(repo, :update, [cs])
    end
  end
  def persist(_,_,_, _, _) do
    {:error, :pending}
  end


  #---------------------------
  #
  #---------------------------
  def as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(table: table) = settings, context, options) do
    # @todo strip transient fields,
    # @todo collapse refs.
    # @todo map fields
    # @todo Inject indexes

    #     Record.defrecord(:field_settings, [name: nil, store: nil, type: nil, transient: false, pii: false, default: nil, acl: nil])
    fields = Noizu.Entity.Meta.fields(entity)
             |> Enum.map(
                  fn
                    ({_, Noizu.Entity.Meta.Field.field_settings(name: name, type: nil) = field_settings}) ->
                      Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_as_record(
                        get_in(entity, [Access.key(name)]),
                        field_settings,
                        settings
                      )
                    ({_, Noizu.Entity.Meta.Field.field_settings(name: name, type: type) = field_settings}) ->
                      {:ok, field_entry} = apply(type, :type_as_entity, [get_in(entity, [Access.key(name)]), context, options])
                      Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_as_record(
                        field_entry,
                        field_settings,
                        settings
                      )
                  end)
             |> List.flatten()
    record = struct(table, fields)
    {:ok, record}
  end

  #---------------------------
  #
  #---------------------------
  def as_entity(entity, settings = Noizu.Entity.Meta.Persistence.persistence_settings(table: table), context, options) do
    with {:ok, identifier} <- Noizu.EntityReference.Protocol.id(entity),
         record <- apply(table, :get!, identifier) do
      from_record(record, settings, context, options)
    end
  end

  #---------------------------
  #
  #---------------------------
  def delete_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(table: table), _context, _options) do
    with {:ok, identifier} <- Noizu.EntityReference.Protocol.id(entity) do
      apply(table, :delete!, identifier)
    end
  end

  #---------------------------
  #
  #---------------------------
  def from_record(record, Noizu.Entity.Meta.Persistence.persistence_settings(kind: kind) = settings, context, options) do
    fields = Noizu.Entity.Meta.fields(kind)
             |> Enum.map(
                  fn
                    ({_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: nil) = field_settings}) ->
                      Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_from_record(
                        nil,
                        record,
                        field_settings,
                        settings,
                        context,
                        options
                      )
                    ({_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: type) = field_settings}) ->
                      {:ok, stub} = apply(type, :stub, [])
                      Noizu.Entity.Store.Ecto.Entity.FieldProtocol.field_from_record(
                        stub, # used for matching
                        record,
                        field_settings,
                        settings,
                        context,
                        options
                      )
                  end)
             |> List.flatten()
    entity = struct(kind, fields)
    {:ok, entity}
  end

end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Any] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  #---------------------------
  #
  #---------------------------
  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    {name, field}
  end


  #---------------------------
  #
  #---------------------------
  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    {name, get_in(record, [Access.key(as_name)])}
  end
end
