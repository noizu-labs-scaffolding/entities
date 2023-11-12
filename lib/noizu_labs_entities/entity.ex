# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entity do
  @callback vsn() :: float
  @callback __noizu_meta__() :: Map.t()

  defmacro __using__(_options \\ nil) do
    quote do
      require Noizu.Entity.Macros
      require Noizu.Entity.Meta.Persistence
      import Noizu.Entity.Meta.Persistence
      import Noizu.Entity.Macros, only: [{:def_entity, 1}]
      Module.register_attribute(__MODULE__, :persistence, accumulate: true)
    end
  end
end

defprotocol Noizu.Entity.Protocol do
  def layer_identifier(entity, layer)
end
