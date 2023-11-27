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
      import Noizu.Entity.Macros,
             only: [
               {:def_entity, 1},
               {:jason_encoder, 0},
               {:jason_encoder, 1}
             ]
      Module.register_attribute(__MODULE__, :persistence, accumulate: true)
    end
  end
end

defprotocol Noizu.Entity.Protocol do
  def layer_identifier(entity, layer)
end

defimpl Noizu.Entity.Protocol, for: Any do
  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end
  def deriving(module, struct, options) do
    # we should be defining a provider rather than requiring these methods be defined for each struct
    quote do
      defimpl  Noizu.EntityReference.Protocol, for: [unquote(module)] do
        def layer_identifier(struct = %{identifier: x}, layer), do: {:ok, x}
      end
    end
  end
end
