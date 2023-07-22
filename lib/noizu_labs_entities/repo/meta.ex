#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Repo.Meta do
  require Noizu.Entity.Meta.Persistence
  # import Noizu.Core.Helpers


  #-------------------
  #
  #-------------------
  def create(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity.__struct__),
         {:ok, entity} <- apply(repo, :__before_create__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_create__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_create__, [entity, context, options])
      do
      {:ok, entity}
    end
  end

  #-------------------
  #
  #-------------------
  def update(entity, context, options) do
    with repo <- Noizu.Entity.Meta.repo(entity.__struct__),
         {:ok, entity} <- apply(repo, :__before_update__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__do_update__, [entity, context, options]),
         {:ok, entity} <- apply(repo, :__after_update__, [entity, context, options])
      do
      {:ok, entity}
    end
  end


  #-------------------
  #
  #-------------------
  def __before_create__(entity, _context, _options) do
    cond do
      entity.identifier ->
        {:ok, entity}
      :else ->
        with {:ok, identifier} <- Noizu.Entity.UID.generate(Module.concat([entity.__struct__, Repo]), node()) do
          {:ok, %{entity| identifier: identifier}}
        end
    end
  end

  #-------------------
  #
  #-------------------
  def __do_create__(entity, context, options) do
    Enum.map(Noizu.Entity.Meta.persistence(entity.__struct__),
      fn(settings) ->
        Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
        protocol = Module.concat([type, Protocol])
        with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
          apply(protocol, :persist, [record, :create, settings, context, options])
        end
      end
    )
    {:ok, entity}
  end

  #-------------------
  #
  #-------------------
  def __after_create__(entity, _context, _options) do
    {:ok, entity}
  end



  #-------------------
  #
  #-------------------
  def __before_update__(entity, _context, _options) do
    cond do
      entity.identifier -> {:ok, entity}
    end
  end

  #-------------------
  #
  #-------------------
  def __do_update__(entity, context, options) do
    Enum.map(Noizu.Entity.Meta.persistence(entity.__struct__),
      fn(settings) ->
        Noizu.Entity.Meta.Persistence.persistence_settings(type: type) = settings
        protocol = Module.concat([type, Protocol])
        with {:ok, record} <- apply(protocol, :as_record, [entity, settings, context, options]) do
          apply(protocol, :persist, [record, :update, settings, context, options])
        end
      end
    )
    {:ok, entity}
  end

  #-------------------
  #
  #-------------------
  def __after_update__(entity, _context, _options) do
    {:ok, entity}
  end

end
