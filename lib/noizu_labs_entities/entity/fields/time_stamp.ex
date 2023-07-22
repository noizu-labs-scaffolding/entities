defmodule Noizu.Entity.TimeStamp do
  defstruct [
    created_on: nil,
    modified_on: nil,
    deleted_on: nil
  ]

  def stub(), do: {:ok, %__MODULE__{}}

  def now(), do: now(DateTime.utc_now())
  def now(now), do: %__MODULE__{created_on: now, modified_on: now}

  def type_as_entity(nil, _context, options) do
    now = options[:current_time] || DateTime.utc_now()
    {:ok, %__MODULE__{created_on: now, modified_on: now}}
  end
  def type_as_entity(%__MODULE__{} = this, _context, options) do
    now = options[:current_time] || DateTime.utc_now()
    {:ok, %__MODULE__{this| created_on: this.created_on || now, modified_on: this.modified_on || now}}
  end
end


defimpl Noizu.Entity.Store.Ecto.Protocol, for: [Noizu.Entity.TimeStamp] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  def as_record(_,_,_,_), do: {:error, :not_supported}
  def from_record(_,_,_,_), do: {:error, :not_supported}
  def persist(_,_,_,_,_), do: {:error, :not_supported}

  def field_as_record(field, Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store), Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table)) do
    name = field_store[table][:name] || field_store[store][:name] || name
    unless name in [:time_stamp, :root] do
      [
        {:"#{name}_created_on", field.created_on},
        {:"#{name}_modified_on", field.modified_on},
        {:"#{name}_deleted_on", field.deleted_on},
      ]
    else
      [
        {:created_on, field.created_on},
        {:modified_on, field.modified_on},
        {:deleted_on, field.deleted_on},
      ]
    end
  end

  def field_from_record(_, record, Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store), Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table)) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    unless as_name in [:time_stamp, :root] do
      field = %Noizu.Entity.TimeStamp{
        created_on: get_in(record, [Access.key(:"#{name}_created_on")]),
        modified_on: get_in(record, [Access.key(:"#{name}_modified_on")]),
        deleted_on: get_in(record, [Access.key(:"#{name}_deleted_on")]),
      }
      {name, field}
    else
      field = %Noizu.Entity.TimeStamp{
        created_on: get_in(record, [Access.key(:created_on)]),
        modified_on: get_in(record, [Access.key(:modified_on)]),
        deleted_on: get_in(record, [Access.key(:deleted_on)]),
      }
      {name, field}
    end
  end

end
