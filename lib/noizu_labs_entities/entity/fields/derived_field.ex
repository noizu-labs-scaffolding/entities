defmodule Noizu.Entity.DerivedField do
  @vsn 1.0
  defstruct vsn: @vsn

  use Noizu.Entity.Field.Behaviour

  def stub(), do: {:ok, %__MODULE__{}}
end

defmodule Noizu.Entity.DerivedField.TypeHelper do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  def as_record(_, _, _, _), do: {:error, :not_supported}
  def as_entity(_, _, _, _), do: {:error, :not_supported}
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  def from_record(_, _, _, _), do: {:error, :not_supported}
  def persist(_, _, _, _, _), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(
          name: name,
          store: field_store,
          options: field_options
        ) = field_settings,
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table) =
          persistence_settings,
        context,
        options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    Enum.find_value(
      [
        field_store[table][:push],
        field_store[store][:push],
        field_options[:push]
      ],
      fn f ->
        case f do
          f when is_function(f, 5) -> {:f5, f}
          _ -> nil
        end
      end
    )
    |> case do
      {:f5, sync_derived} ->
        sync_derived.(field, field_settings, persistence_settings, context, options)

      _ ->
        {:ok, {name, nil}}
    end
  end

  defp as_access_path(p) when is_list(p) do
    Enum.map(
      p,
      fn
        {key, :__defualt__, value} -> Access.key(key, value)
        {:__at__, value} -> Access.at(value)
        key -> Access.key(key)
      end
    )
  end

  def field_from_record(
        field_stub,
        record,
        field_settings =
          Noizu.Entity.Meta.Field.field_settings(
            name: name,
            store: field_store,
            options: field_options
          ),
        persistence_settings =
          Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        context,
        options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    Enum.find_value(
      [
        field_store[table][:pull],
        field_store[store][:pull],
        field_options[:pull]
      ],
      fn f ->
        case f do
          :copy -> :copy
          {:copy, p} when is_list(p) -> {:copy, p}
          :load -> :load
          {:load, p} when is_list(p) -> {:load, p}
          f when is_function(f, 4) -> {:f4, f}
          f when is_function(f, 6) -> {:f6, f}
          _ -> nil
        end
      end
    )
    |> case do
      :copy ->
        {:ok, {name, get_in(record, [Access.key(as_name)])}}

      {:copy, [:^ | t]} when is_list(t) ->
        {:ok, {name, get_in(record, [as_access_path(t)])}}

      {:copy, [:^]} ->
        nil

      {:copy, p} ->
        {:ok, {name, get_in(record, [Access.key(as_name) | as_access_path(p)])}}

      :load ->
        {:ok, {name, get_in(record, [Access.key(:__loader__), Access.key(as_name)])}}

      {:load, [:^ | t]} when is_list(t) ->
        {:ok, {name, get_in(record, [Access.key(:__loader__) | as_access_path(t)])}}

      {:load, [:^]} ->
        nil

      {:load, p} ->
        mp = [Access.key(:__loader__), Access.key(as_name) | as_access_path(p)]
        {:ok, {name, get_in(record, mp)}}

      {:f4, sync_derived} ->
        case sync_derived.(as_name, record, context, field_options) do
          {:ok, v} -> {:ok, {name, v}}
          _ -> nil
        end

      {:f6, sync_derived} ->
        case sync_derived.(
               field_stub,
               record,
               field_settings,
               persistence_settings,
               context,
               options
             ) do
          {:ok, v} -> {:ok, {name, v}}
          _ -> nil
        end

      _ ->
        nil
    end
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Entity.DerivedField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate as_entity(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.DerivedField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Entity.DerivedField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate as_entity(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Entity.DerivedField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.DerivedField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.DerivedField.TypeHelper
end
