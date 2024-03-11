defmodule Noizu.Entity.ReferenceBehavior do

  defmodule Error do
    defexception [:message]

    def message(e) do
      "#{inspect(e.message)}"
    end
  end

  defmacro __using__(options \\ nil) do
    identifier_type = options[:identifier_type] || raise Noizu.Entity.ReferenceBehavior.Error, "identifier_type is required"
    entity = options[:entity] || raise Noizu.Entity.ReferenceBehavior.Error, "entity is required"
    case identifier_type do
      :integer ->
      quote do

        @derive Noizu.EntityReference.Protocol
        defstruct reference: nil
        use Noizu.Entity.Field.Behaviour

        def ecto_gen_string(name) do
          {:ok, "#{name}:integer"}
        end

        def id(%__MODULE__{reference: reference}), do: apply(unquote(entity), :id, [reference])
        def ref(%__MODULE__{reference: reference}), do: apply(unquote(entity), :ref, [reference])
        def entity(%__MODULE__{reference: reference}, context),
            do: apply(unquote(entity), :entity, [reference, context])
        def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
        def stub(), do: {:ok, %__MODULE__{}}

        defimpl Noizu.Entity.Store.Ecto.EntityProtocol do
          def persist(_, _, _, _, _), do: {:error, :not_supported}
          def as_record(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _, _), do: {:error, :not_supported}
          def delete_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _, _), do: {:error, :not_supported}
        end

        defimpl Noizu.Entity.Store.Dummy.EntityProtocol do
          def persist(_, _, _, _, _), do: {:error, :not_supported}
          def as_record(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _, _), do: {:error, :not_supported}
          def delete_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _, _), do: {:error, :not_supported}
        end


        defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol do
          require Noizu.Entity.Meta.Persistence
          require Noizu.Entity.Meta.Field

          require Noizu.EntityReference.Records
          alias Noizu.EntityReference.Records, as: R

          def field_as_record(
                field,
                Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
                Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
                _context,
                _options
              ) do
            name = field_store[table][:name] || field_store[store][:name] || name
            # We need to do a universal ecto conversion
            with {:ok, id} <- apply(unquote(entity), :id, [field]) do
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
              v when is_struct(v) ->
                {:ok, v}

              v = R.ref() ->
                apply(unquote(entity), :entity, [v, context])

              v when is_integer(v) ->
                apply(unquote(entity), :entity, [v, context])

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


        defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol do
          require Noizu.Entity.Meta.Persistence
          require Noizu.Entity.Meta.Field

          require Noizu.EntityReference.Records
          alias Noizu.EntityReference.Records, as: R

          def field_as_record(
                field,
                Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
                Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
                _context,
                _options
              ) do
            name = field_store[table][:name] || field_store[store][:name] || name
            # We need to do a universal ecto conversion
            with {:ok, id} <- apply(unquote(entity), :id, [field]) do
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
              v when is_struct(v) ->
                {:ok, v}

              v = R.ref() ->
                apply(unquote(entity), :entity, [v, context])

              v when is_integer(v) ->
                apply(unquote(entity), :entity, [v, context])

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

      end


      :uuid ->
      quote do

        @derive Noizu.EntityReference.Protocol
        defstruct reference: nil
        use Noizu.Entity.Field.Behaviour

        def ecto_gen_string(name) do
          {:ok, "#{name}:uuid"}
        end

        def id(%__MODULE__{reference: reference}), do: apply(unquote(entity), :id, [reference])
        def ref(%__MODULE__{reference: reference}), do: apply(unquote(entity), :ref, [reference])
        def entity(%__MODULE__{reference: reference}, context),
            do: apply(unquote(entity), :entity, [reference, context])
        def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
        def stub(), do: {:ok, %__MODULE__{}}

        defimpl Noizu.Entity.Store.Ecto.EntityProtocol do
          def persist(_, _, _, _, _), do: {:error, :not_supported}
          def as_record(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _, _), do: {:error, :not_supported}
          def delete_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _, _), do: {:error, :not_supported}
        end


        defimpl Noizu.Entity.Store.Dummy.EntityProtocol do
          def persist(_, _, _, _, _), do: {:error, :not_supported}
          def as_record(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _), do: {:error, :not_supported}
          def as_entity(_, _, _, _, _), do: {:error, :not_supported}
          def delete_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _), do: {:error, :not_supported}
          def from_record(_, _, _, _, _), do: {:error, :not_supported}
        end


        defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol do
          require Noizu.Entity.Meta.Persistence
          require Noizu.Entity.Meta.Field

          require Noizu.EntityReference.Records
          alias Noizu.EntityReference.Records, as: R

          def field_as_record(
                field,
                Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
                Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
                _context,
                _options
              ) do
            name = field_store[table][:name] || field_store[store][:name] || name
            # We need to do a universal ecto conversion
            with {:ok, id} <- apply(unquote(entity), :id, [field]) do
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
              v when is_struct(v) ->
                {:ok, v}

              v = R.ref() ->
                apply(unquote(entity), :entity, [v, context])

              v = <<_::binary-size(16)>> ->
                apply(unquote(entity), :entity, [v, context])

              v =
                <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _,
                  _, _, _, _, _, _, _, _, _>> ->
                apply(unquote(entity), :entity, [v, context])

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


        defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol do
          require Noizu.Entity.Meta.Persistence
          require Noizu.Entity.Meta.Field

          require Noizu.EntityReference.Records
          alias Noizu.EntityReference.Records, as: R

          def field_as_record(
                field,
                Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
                Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
                _context,
                _options
              ) do
            name = field_store[table][:name] || field_store[store][:name] || name
            # We need to do a universal ecto conversion
            with {:ok, id} <- apply(unquote(entity), :id, [field]) do
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
              v when is_struct(v) ->
                {:ok, v}

              v = R.ref() ->
                apply(unquote(entity), :entity, [v, context])

              v = <<_::binary-size(16)>> ->
                apply(unquote(entity), :entity, [v, context])

              v =
                <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _,
                  _, _, _, _, _, _, _, _, _>> ->
                apply(unquote(entity), :entity, [v, context])

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
      end
    end
  end

end
