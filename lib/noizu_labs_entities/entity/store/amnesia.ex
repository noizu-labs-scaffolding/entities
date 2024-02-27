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
  require Noizu.EntityReference.Records
  require Noizu.Entity.Meta.Field
  # ---------------------------
  #
  # ---------------------------
  def persist(%{__struct__: table} = record, _type, Noizu.Entity.Meta.Persistence.persistence_settings(table: table) = _settings, _context, _options) do
    with x = %{} <- apply(table, :write!, [record]) do
      {:ok, x}
    end
  end
  def persist(_,_,_,_,_) do
    {:error, :unsupported}
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
    # todo strip transient fields,
    # collapse refs.

    field_settings =
      Noizu.Entity.Meta.fields(entity)

    # Populate any Indexes
    indexes =
      with true <- function_exported?(table, :set_indexes, 4) || :auto_index,
           {:ok, indexes} <- apply(table, :set_indexes, [entity, settings, context, options]) do
        indexes
      else
        :auto_index ->
          apply(table, :__info__, [:struct])
          |> Enum.map(
               fn
                 (%{field: :id}) ->
                   {:id, entity.id}
                 (%{field: :__meta__}) ->
                   nil
                 (%{field: field}) ->
                   if field_settings[field] do
                     case get_in(entity, [Access.key(field)]) do
                       x = %DateTime{} -> {field, DateTime.to_unix(x)}
                       x = %{__struct__: _} ->
                         with {:ok, ref} <- Noizu.EntityReference.Protocol.ref(x) do
                           {field, ref}
                         end
                       x = Noizu.EntityReference.Records.ref() -> {field, x}
                       _ -> nil
                     end
                   end
               end
             ) |> Enum.reject(&is_nil/1)
        _ ->
          []
      end

    fields =
      field_settings
      |> Enum.map(
           fn
        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: nil) = field_settings} ->
          Noizu.Entity.Store.Amnesia.Entity.FieldProtocol.field_as_record(
            get_in(entity, [Access.key(name)]),
            field_settings,
            settings,
            context,
            options
          )

             {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: {:ecto, _}) = field_settings} ->
               Noizu.Entity.Store.Amnesia.Entity.FieldProtocol.field_as_record(
                 get_in(entity, [Access.key(name)]),
                 field_settings,
                 settings,
                 context,
                 options
               )

        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: type) = field_settings} ->
          with {:ok, field_entry} <- apply(type, :type_as_entity, [get_in(entity, [Access.key(name)]), context, options]) do
            Noizu.Entity.Store.Amnesia.Entity.FieldProtocol.field_as_record(
              field_entry,
              field_settings,
              settings,
              context,
              options
            )
          end
      end)
      |> List.flatten()
      |> List.flatten()
      |> Enum.map(fn
        {:ok, v} -> v
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    entity = Enum.reduce(fields, entity, fn({k,v}, acc) -> put_in(acc, [Access.key(k)], v) end)
    

    record = struct(table, [{:entity, entity}|indexes])
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
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity),
         record <- apply(table, :read!, [id]) do
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
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity) do
      apply(table, :delete!, [id])
    end
  end

  # ---------------------------
  #
  # ---------------------------
  def from_record(%{entity: entity}, _settings, context, _options) do
    unpack = Noizu.Entity.Meta.fields(entity)
             |> Enum.map(
                  fn
                    ({field, Noizu.Entity.Meta.Field.field_settings(options: field_options)}) ->
                      with true <- field_options[:auto],
                           {:ok, unpacked} <- Noizu.EntityReference.Protocol.entity(get_in(entity, [Access.key(field)]), context)
                        do
                        {field, unpacked}
                      else
                         _ -> nil
                      end
                    (_) -> nil
                  end)
             |> Enum.reject(&is_nil/1)
    unless unpack == [] do
      entity = Enum.reduce(unpack, entity, fn({k,v}, acc) -> put_in(acc, [Access.key(k)], v) end)      
      {:ok, entity}
    else
      {:ok, entity}
    end
  end


  def from_record(_, _settings, _context, _options) do
    {:error, :invalid_record}
  end
  def from_record(_, record, settings, context, options) do
    # @todo refresh entity with record
    from_record(record, settings, context, options)
  end

end

defimpl Noizu.Entity.Store.Amnesia.Entity.FieldProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field
  def field_as_record(_field, Noizu.Entity.Meta.Field.field_settings(name: name, transient: true) = _field_settings, _persistence_settings, _context, _options) do
    {:ok, {name, nil}}
  end
  def field_as_record(field, Noizu.Entity.Meta.Field.field_settings(name: name) = _field_settings, _persistence_settings, _context, _options) do
    {:ok, {name, field}}
  end
  def field_from_record(
        _field,
        _record,
        _field_settings,
        _persistence_settings,
        _context,
        _options
      ),
      do: {:error, {:unsupported, Amnesia}} # We simply grab Amnesia for default cases. Multi Table scenarios require Overrides
end





defimpl Noizu.Entity.Store.Amnesia.EntityProtocol, for: [Noizu.Entity.UUIDReference] do
  defdelegate persist(entity, type, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper

  defdelegate as_record(entity, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper

  defdelegate as_entity(entity, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper
  defdelegate as_entity(entity, record, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper

  defdelegate from_record(record, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper
  defdelegate from_record(entity, record, settings, context, options),
              to: Noizu.Entity.UUIDReference.TypeHelper
end

defimpl Noizu.Entity.Store.Amnesia.Entity.FieldProtocol, for: [Noizu.Entity.UUIDReference] do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  #alias Noizu.EntityReference.Records, as: R

  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.UUIDReference.TypeHelper

   def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, ref} <- Noizu.EntityReference.Protocol.ref(field) do
      {:ok, {name, ref}}
    end
  end
end
