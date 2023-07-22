defmodule Noizu.Entity.Reference do
  @derive Noizu.EntityReference.Protocol
  defstruct [
    reference: nil,
  ]
  use Noizu.Entity.Field.Behaviour

  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)
  def entity(%__MODULE__{reference: reference}, context), do: Noizu.EntityReference.Protocol.entity(reference, context)

  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
  def stub(), do: {:ok, %__MODULE__{}}
end


defmodule  Noizu.Entity.Reference.TypeHelper do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field


  def persist(_,_,_,_,_), do: {:error, :not_supported}
  def as_record(_,_,_,_), do: {:error, :not_supported}
  def as_entity(_,_,_,_), do: {:error, :not_supported}
  def delete_record(_,_,_,_), do: {:error, :not_supported}
  def from_record(_,_,_,_), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(field) do
      {name, id}
    end
  end

  def field_from_record(
        _,
        _record,
        Noizu.Entity.Meta.Field.field_settings(name: _name, store: _field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: _store, table: _table),
        _context,
        _options
      ) do
    #as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    {:error, :pending}
  end
end



defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Entity.Reference] do
  defdelegate persist(entity,type,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate as_record(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate as_entity(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate delete_record(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate from_record(record,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.Reference] do
  defdelegate field_from_record(field, record, field_settings, persistence_settings, context, options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate field_as_record(field, field_settings, persistence_settings, context, options), to: Noizu.Entity.Reference.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Entity.Reference] do
  defdelegate persist(entity,type,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate as_record(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate as_entity(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate delete_record(entity,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate from_record(record,settings,context,options), to: Noizu.Entity.Reference.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Entity.Reference] do
  defdelegate field_from_record(field, record, field_settings, persistence_settings, context, options), to: Noizu.Entity.Reference.TypeHelper
  defdelegate field_as_record(field, field_settings, persistence_settings, context, options), to: Noizu.Entity.Reference.TypeHelper
end
