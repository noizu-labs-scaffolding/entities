#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Repo.Macros do
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL

  #----------------------------------------
  # def_repo
  #----------------------------------------
  defmacro def_repo() do
    quote do
          @entity __MODULE__
                  |> Module.split()
                  |> Enum.slice(0..-2)
                  |> Module.concat()
          @poly false

          defstruct [
            entities: [],
            length: 0,
            meta: nil,
            __transient__: nil
          ]

          defdelegate create(entity, context, options), to: Noizu.Repo.Meta
          defdelegate update(entity, context, options), to: Noizu.Repo.Meta

          defdelegate __before_create__(entity, context, options), to: Noizu.Repo.Meta
          defdelegate __do_create__(entity, context, options), to: Noizu.Repo.Meta
          defdelegate __after_create__(entity, context, options), to: Noizu.Repo.Meta

          defdelegate __before_update__(entity, context, options), to: Noizu.Repo.Meta
          defdelegate __do_update__(entity, context, options), to: Noizu.Repo.Meta
          defdelegate __after_update__(entity, context, options), to: Noizu.Repo.Meta

          defoverridable [
            create: 3,
            update: 3,

            __before_create__: 3,
            __do_create__: 3,
            __after_create__: 3,

            __before_update__: 3,
            __do_update__: 3,
            __after_update__: 3,
          ]
    end
  end
end
