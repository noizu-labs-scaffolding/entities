defmodule Noizu.Entity.UUIDReference do
  @moduledoc """
  A entity type that converted entities to and from uuids/refs for persistence.
  """

  @derive Noizu.EntityReference.Protocol
  defstruct reference: nil
  use Noizu.Entity.Field.Behaviour

  # ----------------
  # ecto_gen_string
  # ----------------
  def ecto_gen_string(name) do
    {:ok, "#{name}:uuid"}
  end

  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)

  def entity(%__MODULE__{reference: reference}, context),
    do: Noizu.EntityReference.Protocol.entity(reference, context)

  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
  def stub(), do: {:ok, %__MODULE__{}}

  # *******************************************
  # *******************************************
  # Ecto.Type support
  # *******************************************
  # *******************************************
  use Ecto.Type

  # ----------------------------
  # type
  # ----------------------------
  @doc false
  def type, do: :uuid

  # ----------------------------
  # cast
  # ----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    case v do
      nil ->
        {:ok, nil}

      <<_::binary-size(16)>> ->
        Noizu.Entity.UID.ref(v)

      <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, _,
        _, _, _, _, _, _, _>> ->
        Noizu.Entity.UID.ref(v)

      %{__struct__: _} ->
        Noizu.EntityReference.Protocol.ref(v)

      _ ->
        :error
    end
  end

  # ----------------------------
  # cast!
  # ----------------------------
  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  def cast!(value) do
    case cast(value) do
      {:ok, v} -> v
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  # ----------------------------
  # dump
  # ----------------------------
  @doc false
  def dump(<<_::binary-size(16)>> = v) do
    {:ok, v}
  end

  def dump(
        <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _,
          _, _, _, _, _, _, _, _>> = v
      ) do
    {:ok, v}
  end

  def dump(v) when is_nil(v) do
    {:ok, v}
  end

  def dump(v) do
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(v) do
      {:ok, id}
    else
      _ ->
        {:ok, nil}
    end
  end

  # ----------------------------
  # load
  # ----------------------------
  def load(v) do
    case v do
      nil ->
        {:ok, nil}

      <<_::binary-size(16)>> ->
        Noizu.Entity.UID.ref(v)

      <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, _,
        _, _, _, _, _, _, _>> ->
        Noizu.Entity.UID.ref(v)

      v when is_struct(v) ->
        Noizu.EntityReference.Protocol.ref(v)

      _ ->
        raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect(v)}"
    end
  end
end

defmodule Noizu.Entity.UUIDReference.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  def field_as_record(field, field_settings, persistence_settings, context, options)

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(
          store: store,
          table: table,
          type: Noizu.Entity.Store.Amnesia
        ),
        _,
        _
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, ref} <- Noizu.EntityReference.Protocol.ref(field) do
      {:ok, {name, ref}}
    end
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _,
        _
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
        Noizu.Entity.Meta.Field.field_settings(
          options: field_options,
          name: name,
          store: field_store
        ),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    case Map.get(record, as_name) do
      v when is_struct(v) ->
        {:ok, v}

      v = R.ref() ->
        if field_options[:auto] do
          Noizu.EntityReference.Protocol.entity(v, context)
        else
          Noizu.EntityReference.Protocol.ref(v)
        end

      v = <<_::binary-size(16)>> ->
        v = Noizu.Entity.UID.ref(v)

        if field_options[:auto] do
          Noizu.EntityReference.Protocol.entity(v, context)
        else
          Noizu.EntityReference.Protocol.ref(v)
        end

      v =
          <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _,
            _, _, _, _, _, _, _, _, _>> ->
        v = Noizu.Entity.UID.ref(v)

        if field_options[:auto] do
          Noizu.EntityReference.Protocol.entity(v, context)
        else
          Noizu.EntityReference.Protocol.ref(v)
        end

      v ->
        v
    end
    |> case do
      nil -> {:ok, {name, nil}}
      {:ok, entity} -> {:ok, {name, entity}}
      v -> v
    end
  end
end

for store <- [
      Noizu.Entity.Store.Amnesia,
      Noizu.Entity.Store.Dummy,
      Noizu.Entity.Store.Ecto,
      Noizu.Entity.Store.Mnesia,
      Noizu.Entity.Store.Redis
    ] do
  entity_protocol = Module.concat(store, EntityProtocol)
  entity_field_protocol = Module.concat(store, Entity.FieldProtocol)
  type_helper = Noizu.Entity.UUIDReference.TypeHelper

  defimpl entity_field_protocol, for: [Noizu.Entity.UUIDReference] do
    @type_helper type_helper
    defdelegate field_from_record(
                  field,
                  record,
                  field_settings,
                  persistence_settings,
                  context,
                  options
                ),
                to: @type_helper

    defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
      to: @type_helper
  end
end
