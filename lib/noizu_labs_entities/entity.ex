#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity do
  @callback vsn() :: float
  @callback __noizu_meta__() :: Map.t

  defmacro __using__(options \\ nil) do
    quote do
      use Noizu.Entity.Meta, unquote(options)
      require Noizu.Entity.Macros
      import Noizu.Entity.Macros, only: [{:def_entity, 1}]
    end
  end
end