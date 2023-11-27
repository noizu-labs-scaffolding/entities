# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Dummy.EntityProtocol do
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

defprotocol Noizu.Entity.Store.Dummy.Entity.FieldProtocol do
  @fallback_to_any true
  def field_as_record(field, field_settings, persistence_settings, context, options)
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end

defmodule Noizu.Entity.Store.Dummy.StorageLayer do
  @table_name :dummy_storage_device

  def init do
    create_table()
  end

  defp create_table do
    case :ets.info(@table_name) do
      :undefined -> :ets.new(@table_name, [:public, :named_table])
      _ -> :ok
    end
  end

  def write(identifier, name_space, entity) do
    # IO.inspect(entity, label:  "WRITE #{identifier}:#{name_space}")
    create_table()
    key = {identifier, name_space}
    :ets.insert(@table_name, {key, entity})
  end

  def delete(identifier, name_space) do
    # IO.puts "delete #{identifier}:#{name_space}"
    create_table()
    key = {identifier, name_space}
    :ets.delete(@table_name, key)
  end

  def get(identifier, name_space) do
    # IO.puts "get #{identifier}:#{name_space}"
    create_table()
    key = {identifier, name_space}

    case :ets.lookup(@table_name, key) do
      [{_, entity}] -> {:ok, entity}
      [] -> {:error, :not_found}
    end
  end
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ---------------------------
  #
  # ---------------------------
  def persist(
        record = %{identifier: id},
        _type,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        _context,
        _options
      ) do
    # Verify table match
    Noizu.Entity.Store.Dummy.StorageLayer.write(id, table, record)
  end

  def persist(_, _, _, _, _) do
    {:error, :pending}
  end

  # ---------------------------
  #
  # ---------------------------
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
      Noizu.Entity.Meta.fields(entity)
      |> Enum.map(fn
        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: nil) = field_settings} ->

          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_as_record(
            get_in(entity, [Access.key(name)]),
            field_settings,
            settings,
            context,
            options
          )

        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: type) = field_settings} ->
          {:ok, field_entry} = apply(type, :type_as_entity, [get_in(entity, [Access.key(name)]), context, options])

          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_as_record(
            field_entry,
            field_settings,
            settings,
            context,
            options
          )
      end)
      |> List.flatten()
      |> Enum.map(
           fn
             {:ok, v} -> v
             _ -> nil
           end)
      |> Enum.reject(&is_nil/1)

    record = struct(table, fields)
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
         {:ok, record} <- Noizu.Entity.Store.Dummy.StorageLayer.get(identifier, table) do
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
      Noizu.Entity.Store.Dummy.StorageLayer.delete(identifier, table)
      :ok
    end
  end

  # ---------------------------
  #
  # ---------------------------
  def from_record(_, record, settings, context, options) do
    # todo refresh entity from record
    from_record(record, settings, context, options)
  end

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
          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_from_record(
            nil,
            record,
            field_settings,
            settings,
            context,
            options
          )
        {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: type) = field_settings} ->
          {:ok, stub} = apply(type, :stub, [])

          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_from_record(
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
      |> Enum.map(
           fn
             {:ok, v} -> v
             _ -> nil
           end)
      |> Enum.reject(&is_nil/1)

    entity = struct(kind, fields)
    {:ok, entity}
  end
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Any] do
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
