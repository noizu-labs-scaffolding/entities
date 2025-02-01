defmodule Noizu.Entity.Extended.UUIDReference do
  @derive Noizu.EntityReference.Protocol
  defstruct reference: nil
  use Noizu.Entity.Field.Behaviour

  def ecto_gen_string(name) do
    {:ok, ["#{name}_ref:uuid","#{name}_ref_type:uuid"]}
  end

  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)
  def entity(%__MODULE__{reference: reference}, context),
    do: Noizu.EntityReference.Protocol.entity(reference, context)

  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}

  def stub(), do: {:ok, %__MODULE__{}}
end

defmodule Noizu.Entity.Extended.UUIDReference.TypeHelper do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  def persist(_, _, _, _, _), do: {:error, :not_supported}
  def as_record(_, _, _, _), do: {:error, :not_supported}
  def as_record(_, _, _, _, _), do: {:error, :not_supported}
  def fetch_as_entity(_, _, _, _), do: {:error, :not_supported}
  def as_entity(_, _, _, _, _), do: {:error, :not_supported}
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  def from_record(_, _, _, _), do: {:error, :not_supported}
  def merge_from_record(_, _, _, _, _), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, R.ref(module: m, id: id)} <- Noizu.EntityReference.Protocol.ref(field) do
      [
        {:ok, {:"#{as_name}_ref", id}},
        {:ok, {:"#{as_name}_ref_type", Noizu.UUID.uuid5(:dns, "#{m}")}},
      ]
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

    ref_field_key = :"#{as_name}_ref"
    ref_type_field_key = :"#{as_name}_ref_type"

    ref_field = Map.get(record, ref_field_key)
    ref_type_field = Map.get(record, ref_type_field_key)
    cond do
      is_nil(ref_field) -> nil
      is_nil(ref_type_field) ->
        case ref_field do
          v when is_struct(v) ->
            {:ok, v}

          v = R.ref() ->
            Noizu.EntityReference.Protocol.entity(v, context)

          v = <<_::binary-size(16)>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              Noizu.EntityReference.Protocol.entity(ref, context)
            end
          v =
            <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _,
              _, _, _, _, _, _, _, _, _>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              Noizu.EntityReference.Protocol.entity(ref, context)
            end

          v ->
            v
        end
      :else ->
        case ref_field do
          v when is_struct(v) ->
            {:ok, v}
          v = R.ref() ->
            Noizu.EntityReference.Protocol.entity(v, context)
          v = <<_::binary-size(16)>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              Noizu.EntityReference.Protocol.entity(ref, context)
            end
          v =
            <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _,
              _, _, _, _, _, _, _, _, _>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref({:id, v, :type_id, ref_type_field}) do
              Noizu.EntityReference.Protocol.entity(ref, context)
            end
          v when is_integer(v) ->
            with {:ok, ref} <- Noizu.Entity.UID.ref({:id, v, :type_id, ref_type_field}) do
              Noizu.EntityReference.Protocol.entity(ref, context)
            end
          v ->
            v
        end
    end
    |> case do
      nil -> {:ok, {name, nil}}
      {:ok, entity} -> {:ok, {name, entity}}
      v -> v
    end
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Entity.Extended.UUIDReference] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate fetch_as_entity(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.Extended.UUIDReference] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Entity.Extended.UUIDReference] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate fetch_as_entity(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Entity.Extended.UUIDReference] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.Extended.UUIDReference.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.Extended.UUIDReference.TypeHelper
end
