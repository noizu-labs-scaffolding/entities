defmodule Noizu.Entity.Reference do
  @derive Noizu.EntityReference.Protocol
  defstruct [
    reference: nil,
  ]

  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)
  def entity(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.entity(reference)

  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
  def stub(), do: {:ok, %__MODULE__{}}
end


defimpl Noizu.Entity.Store.Ecto.Protocol, for: [Noizu.Entity.Reference] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  def as_record(_, _), do: {:error, :not_supported}
  def from_record(_,_), do: {:error, :not_supported}

  def field_as_record(field, Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store), Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table)) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(field) do
      {name, id}
    end |> IO.inspect(label: :field_as_record)
  end

  def field_from_record(_, record, Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store), Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table)) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    {:error, :pending}
  end
end