defmodule Noizu.Entity.Field.Behaviour do
  @callback as_record(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback as_entity(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback delete_record(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback from_record(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback persist(
              entity :: any,
              action_type :: atom,
              settings :: any,
              context :: any,
              options :: any
            ) :: any

  @callback type__before_create(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback type__before_update(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback type__after_delete(entity :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}

  @callback type_as_entity(entity :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback stub() :: {:ok, any} | {:error, any}

  @callback field_as_record(field :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}
  @callback field_from_record(field :: any, settings :: any, context :: any, options :: any) ::
              {:ok, any} | {:error, any}

  defmacro __using__(_options \\ nil) do
    quote do
      @behaviour Noizu.Entity.Field.Behaviour
      def as_record(_, _, _, _), do: {:error, {:as_record, :unsupported}}
      def as_entity(_, _, _, _), do: {:error, {:as_entity, :unsupported}}
      def delete_record(_, _, _, _), do: {:error, {:delete_record, :unsupported}}
      def from_record(_, _, _, _), do: {:error, {:from_record, :unsupported}}
      def persist(_, _, _, _, _), do: {:error, {:persist, :unsupported}}

      def type__before_create(_, _, _, _),
        do: {:error, {:unsupported, __MODULE__, :type__before_create}}

      def type__before_update(_, _, _, _),
        do: {:error, {:unsupported, __MODULE__, :type__before_update}}

      def type__after_delete(_, _, _, _),
        do: {:error, {:unsupported, __MODULE__, :type__after_delete}}

      def type_as_entity(this, _, _), do: {:ok, this}
      def stub(), do: {:ok, %__MODULE__{}}

      def field_as_record(_, _, _, _), do: {:error, :field_as_record}
      def field_from_record(_, _, _, _), do: {:error, :field_from_record}

      defoverridable as_record: 4,
                     as_entity: 4,
                     delete_record: 4,
                     from_record: 4,
                     persist: 5,
                     type__before_create: 4,
                     type__before_update: 4,
                     type__after_delete: 4,
                     type_as_entity: 3,
                     stub: 0,
                     field_as_record: 4,
                     field_from_record: 4
    end
  end
end
