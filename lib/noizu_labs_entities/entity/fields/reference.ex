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



  #*******************************************
  #*******************************************
  # Ecto.Type support
  #*******************************************
  #*******************************************
  use Ecto.Type

  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :integer

  #----------------------------
  # cast
  #----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      is_integer(v) -> Noizu.Entity.UID.ref(v)
      is_struct(v) -> Noizu.EntityReference.Protocol.ref(v)
      :else -> :error
    end
  end

  #----------------------------
  # cast!
  #----------------------------
  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  def cast!(value) do
    case cast(value) do
      {:ok, v} -> v
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  #----------------------------
  # dump
  #----------------------------
  @doc false
  def dump(v) when is_integer(v) do
    {:ok, v}
  end
  def dump(v) when is_nil(v) do
    {:ok, v}
  end
  def dump(v) do
    with {:ok, identifier} <- Noizu.EntityReference.Protocol.id(v) do
      {:ok, identifier}
    else
      _ ->
        {:ok, 0}
    end
  end

  #----------------------------
  # load
  #----------------------------
  def load(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      is_integer(v) -> Noizu.Entity.UID.ref(v)
      is_struct(v) -> Noizu.EntityReference.Protocol.ref(v)
      :else -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end

end


defmodule  Noizu.Entity.Reference.TypeHelper do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

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
      {:ok, {name, id}}
    end
  end

  def field_from_record(
        _,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    case Map.get(record, as_name) do
      v when is_struct(v) -> {:ok, v}
      v = R.ref() -> Noizu.EntityReference.Protocol.entity(v, context)
      v when is_integer(v) -> Noizu.Entity.UID.ref(v) |> Noizu.EntityReference.Protocol.entity(context)
      v -> v
    end |> case do
             nil -> {:ok, {name, nil}}
             {:ok, entity} -> {:ok, {name, entity}}
             v -> v
           end
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
