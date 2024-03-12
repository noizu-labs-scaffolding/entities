# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Repo.Meta do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Identifier
  # import Noizu.Core.Helpers

  # -------------------
  #
  # -------------------
  def create(%Ecto.Changeset{} = changeset, context, options) do
    if changeset.valid? do
      Enum.reduce(changeset.changes, changeset.data, fn {field, value}, acc ->
        put_in(acc, [Access.key(field)], value)
      end)
      |> create(context, options)
    else
      {:error, changeset.errors}
    end
  end

  def create(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity),
         {:ok, entity} <- apply(repo, :__before_create__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_create__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_create__, [entity, context, options]) do
      {:ok, entity}
    end
  end

  # -------------------
  #
  # -------------------
  def update(%Ecto.Changeset{} = changeset, context, options) do
    if changeset.valid? do
      Enum.reduce(changeset.changes, changeset.data, fn {field, value}, acc ->
        put_in(acc, [Access.key(field)], value)
      end)
      |> update(context, options)
    else
      {:error, changeset.errors}
    end
  end
  def update(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity),
         {:ok, entity} <- apply(repo, :__before_update__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_update__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_update__, [entity, context, options]) do
      {:ok, entity}
    end
  end

  # -------------------
  #
  # -------------------
  def get(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity),
         {:ok, entity} <- apply(repo, :__before_get__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_get__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_get__, [entity, context, options]) do
      {:ok, entity}
    end
  end

  # -------------------
  #
  # -------------------
  def delete(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity),
         {:ok, entity} <- apply(repo, :__before_delete__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_delete__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_delete__, [entity, context, options]) do
      {:ok, entity}
    end
  end

  # -------------------
  #
  # -------------------
  def __before_create__(entity, context, options) do
    cond do
      entity.id ->
        {:ok, entity}

      :else ->
        with {:ok, {id, index}} <-
               Noizu.Entity.UID.generate(entity.__struct__.__noizu_meta__()[:repo], node()) do
          case Noizu.Entity.Meta.id(entity) do
            {field, Noizu.Entity.Meta.Identifier.id_settings(type: :integer)} ->
              id =
                Noizu.Entity.Meta.IntegerIdentifier.format_id(entity, id, index)

              {:ok, put_in(entity, [Access.key(field)], id)}

            {field, Noizu.Entity.Meta.Identifier.id_settings(type: :uuid)} ->
              id =
                Noizu.Entity.Meta.UUIDIdentifier.format_id(entity, id, index)

              {:ok, put_in(entity, [Access.key(field)], id)}

            {field, Noizu.Entity.Meta.Identifier.id_settings(type: :ref)} ->
              id =
                Noizu.Entity.Meta.RefIdentifier.format_id(entity, id, index)

              {:ok, put_in(entity, [Access.key(field)], id)}

            {field, Noizu.Entity.Meta.Identifier.id_settings(type: :dual_ref)} ->
              id =
                Noizu.Entity.Meta.DualRefIdentifier.format_id(entity, id, index)

              {:ok, put_in(entity, [Access.key(field)], id)}

            {field, Noizu.Entity.Meta.Identifier.id_settings(type: user_defined)} ->
              id = apply(user_defined, :format_id, [entity, id, index])
              {:ok, put_in(entity, [Access.key(field)], id)}
          end
        end
    end
    |> case do
         {:ok, entity} ->
           entity =
             Noizu.Entity.Meta.fields(entity)
             |> Enum.map(fn
               {_, Noizu.Entity.Meta.Field.field_settings(type: nil)} ->
                 nil
               {_, Noizu.Entity.Meta.Field.field_settings(type: {:ecto, _})} ->
                 nil
               {field, Noizu.Entity.Meta.Field.field_settings(type: type) = field_settings} ->
                 with {:ok, update} <-
                        apply(type, :type__before_create, [
                          get_in(entity, [Access.key(field)]),
                          field_settings,
                          context,
                          options
                        ]) do
                   {field, update}
                 else
                   _ -> nil
                 end
             end)
             |> Enum.filter(& &1)
             |> Enum.reduce(entity, fn {field, update}, acc -> Map.put(acc, field, update) end)

           {:ok, entity}

         v ->
           v
       end
  end

  # -------------------
  #
  # -------------------
  def __do_create__(entity, context, options) do
    Noizu.Entity.Meta.persistence(entity)
    |> Enum.map(fn settings ->
      Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
      protocol = Module.concat([type, EntityProtocol])

      with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
        apply(protocol, :persist, [record, :create, settings, context, options])
      end
    end)

    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __after_create__(entity, _context, _options) do
    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __before_update__(entity, context, options) do
    cond do
      entity.id -> {:ok, entity}
      :else -> {:error, :id_required}
    end
    |> case do
         {:ok, entity} ->
           entity =
             Noizu.Entity.Meta.fields(entity)
             |> Enum.map(fn
               {_, Noizu.Entity.Meta.Field.field_settings(type: nil)} ->
                 nil

               {field, Noizu.Entity.Meta.Field.field_settings(type: type) = field_settings} ->
                 with {:ok, update} <-
                        apply(type, :type__before_update, [
                          get_in(entity, [Access.key(field)]),
                          field_settings,
                          context,
                          options
                        ]) do
                   {field, update}
                 else
                   _ -> nil
                 end
             end)
             |> Enum.filter(& &1)
             |> Enum.reduce(entity, fn {field, update}, acc -> Map.put(acc, field, update) end)

           {:ok, entity}

         v ->
           v
       end
  end

  # -------------------
  #
  # -------------------
  def __do_update__(entity, context, options) do
    Noizu.Entity.Meta.persistence(entity)
    |> Enum.map(fn settings ->
      Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
      protocol = Module.concat([type, EntityProtocol])

      with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
        apply(protocol, :persist, [record, :update, settings, context, options])
      end
    end)

    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __after_update__(entity, _context, _options) do
    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __before_get__(entity, _context, _options) do
    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __do_get__(entity, context, options) do
    Noizu.Entity.Meta.persistence(entity)
    |> Enum.reduce_while({:error, :not_found}, fn settings, _ ->
      Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
      protocol = Module.concat([type, EntityProtocol])

      with {:ok, entity} <- apply(protocol, :as_entity, [entity, settings, context, options]) do
        {:halt, {:ok, entity}}
      else
        err -> {:cont, err}
      end
    end)
  end

  # -------------------
  #
  # -------------------
  def __after_get__(entity, _context, _options) do
    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __before_delete__(entity, _context, _options) do
    cond do
      entity.id -> {:ok, entity}
    end
  end

  # -------------------
  #
  # -------------------
  def __do_delete__(entity, context, options) do
    Noizu.Entity.Meta.persistence(entity.__struct__)
    |> Enum.reverse()
    |> Enum.map(fn settings ->
      Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
      protocol = Module.concat([type, EntityProtocol])
      apply(protocol, :delete_record, [entity, settings, context, options])
    end)

    {:ok, entity}
  end

  # -------------------
  #
  # -------------------
  def __after_delete__(entity, context, options) do
    Noizu.Entity.Meta.fields(entity)
    |> Enum.map(fn
      {_, Noizu.Entity.Meta.Field.field_settings(type: nil)} ->
        nil

      {field, Noizu.Entity.Meta.Field.field_settings(type: type) = field_settings} ->
        with {:ok, update} <-
               apply(type, :type__after_delete, [
                 get_in(entity, [Access.key(field)]),
                 field_settings,
                 context,
                 options
               ]) do
          {field, update}
        else
          _ -> nil
        end
    end)

    {:ok, entity}
  end
end
