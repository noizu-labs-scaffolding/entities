defmodule Noizu.Support.Entity.TestField do
  @derive Noizu.EntityReference.Protocol
  defstruct identifier: nil,
            sno: nil

  use Noizu.Entity.Field.Behaviour

  def id(%__MODULE__{identifier: identifier}), do: {:ok, identifier}
  def ref(%__MODULE__{identifier: identifier}), do: {:ok, {:ref, __MODULE__, identifier}}
  def entity(%__MODULE__{} = this, _), do: {:ok, this}

  def type__before_create(nil, _, _, _), do: nil

  def type__before_create(sno, _, _, _) when is_bitstring(sno) do
    entity = %__MODULE__{
      identifier: 0xF00BA7,
      sno: sno
    }

    {:ok, entity}
  end

  def type__before_create(%__MODULE__{} = this, _, _, _) do
    cond do
      this.identifier -> {:ok, this}
      :else -> {:ok, %{this | identifier: 31337}}
    end
  end

  def type__before_update(nil, _, _, _), do: nil

  def type__before_update(sno, _, _, _) when is_bitstring(sno) do
    entity = %__MODULE__{
      identifier: 0xF00BA8,
      sno: sno
    }

    {:ok, entity}
  end

  def type__before_update(%__MODULE__{} = this, _, _, _) do
    {:ok, %{this | sno: this.sno <> "_updated"}}
  end

  def type__after_delete(_, _, _, _), do: nil
end

defmodule Noizu.Support.Entity.TestField.TypeHelper do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  def persist(_, _, _, _, _), do: {:error, :not_supported}
  def as_record(_, _, _, _), do: {:error, :not_supported}
  def as_entity(_, _, _, _), do: {:error, :not_supported}
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  def from_record(_, _, _, _), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    # We need to do a universal ecto conversion
    [
      {:ok, {:"#{as_name}_identifier", field.identifier}},
      {:ok, {:"#{as_name}_sno", field.sno}}
    ]
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
    identifier = Map.get(record, :"#{as_name}_identifier")
    sno = Map.get(record, :"#{as_name}_sno")

    {:ok, {name, %Noizu.Support.Entity.TestField{identifier: identifier, sno: sno}}}
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_entity(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_entity(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end
