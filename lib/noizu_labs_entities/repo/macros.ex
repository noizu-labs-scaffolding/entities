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
    end
  end
end
