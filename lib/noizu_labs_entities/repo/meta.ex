#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Repo.Meta do
  require Noizu.Entity.Meta.Persistence
  import Noizu.Core.Helpers
  def create(entity, context, options) do
    # @todo before_create
    identifier = cond do
      entity.identifier -> entity.identifier
      :else ->
        Noizu.Entity.UID.generate(Module.concat([entity.__struct__, Repo]), node()) |> ok?()
    end
    entity = %{entity| identifier: identifier}
    Enum.map(Noizu.Entity.Meta.persistence(entity.__struct__),
      fn(settings) ->
        create_as_record(entity, settings, context, options)
      end
    )
    # @todo after_create
    {:ok, entity}
  end

  def create_as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings, context, options) do
    protocol = Module.concat([type, Protocol])
    with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
      apply(protocol, :persist, [record, :create, settings, context, options])
    end
  end

  def update(entity, context, options) do
    # @todo before_create
    identifier = cond do
      entity.identifier -> entity.identifier
    end
    Enum.map(Noizu.Entity.Meta.persistence(entity.__struct__),
      fn(settings) ->
        update_as_record(entity, settings, context, options)
      end
    )
    # @todo after_create
    {:ok, entity}
  end

  def update_as_record(entity, Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings, context, options) do
    protocol = Module.concat([type, Protocol])
    with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
      apply(protocol, :persist, [record, :update, settings, context, options])
      |> IO.inspect(label: "PERSIST, :update")
    end
  end


end