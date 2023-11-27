defmodule Noizu.Entity.TimeStamp do
  defstruct created_on: nil,
            modified_on: nil,
            deleted_on: nil

  use Noizu.Entity.Field.Behaviour

  def stub(), do: {:ok, %__MODULE__{}}

  def now(), do: now(DateTime.utc_now())
  def now(now), do: %__MODULE__{created_on: now, modified_on: now}

  def type_as_entity(nil, _context, options) do
    now = options[:current_time] || DateTime.utc_now()
    {:ok, %__MODULE__{created_on: now, modified_on: now}}
  end

  def type_as_entity(%__MODULE__{} = this, _context, options) do
    now = options[:current_time] || DateTime.utc_now()

    {:ok,
     %__MODULE__{this | created_on: this.created_on || now, modified_on: this.modified_on || now}}
  end
end

defmodule Noizu.Entity.TimeStamp.TypeHelper do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  def as_record(_, _, _, _), do: {:error, :not_supported}
  def as_entity(_, _, _, _), do: {:error, :not_supported}
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  def from_record(_, _, _, _), do: {:error, :not_supported}
  def persist(_, _, _, _, _), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name

    unless name in [:time_stamp, :root] do
      [
        {:ok, {:"#{name}_created_on", field.created_on}},
        {:ok, {:"#{name}_modified_on", field.modified_on}},
        {:ok, {:"#{name}_deleted_on", field.deleted_on}}
      ]
    else
      [
        {:ok, {:created_on, field.created_on}},
        {:ok, {:modified_on, field.modified_on}},
        {:ok, {:deleted_on, field.deleted_on}}
      ]
    end
  end

  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    unless as_name in [:time_stamp, :root] do
      field = %Noizu.Entity.TimeStamp{
        created_on: get_in(record, [Access.key(:"#{name}_created_on")]),
        modified_on: get_in(record, [Access.key(:"#{name}_modified_on")]),
        deleted_on: get_in(record, [Access.key(:"#{name}_deleted_on")])
      }

      {:ok, {name, field}}
    else
      field = %Noizu.Entity.TimeStamp{
        created_on: get_in(record, [Access.key(:created_on)]),
        modified_on: get_in(record, [Access.key(:modified_on)]),
        deleted_on: get_in(record, [Access.key(:deleted_on)])
      }

      {:ok, {name, field}}
    end
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_record(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper
  defdelegate as_entity(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end



defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_record(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper
  defdelegate as_entity(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end



defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Entity.TimeStamp] do
  require Noizu.Entity.Meta.Field
  def field_from_record(
        field,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name),
        persistence_settings,
        context,
        options
      )
    do
    {:ok, {name, get_in(record, [Access.key(name)])}}
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name) = field_settings,
        persistence_settings,
        context,
        options)
      do
        {:ok, {name, field}}
    end
end
