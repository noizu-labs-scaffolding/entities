#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entities do
  defmacro __using__(options \\ nil) do
    quote do
      use Noizu.Entity.Meta, unquote(options)

      Module.register_attribute(__MODULE__, :persistence, accumulate: true)
      Module.register_attribute(__MODULE__, :vsn, accumulate: false)
      Module.register_attribute(__MODULE__, :sref, accumulate: false)

      use Noizu.Entity
      use Noizu.Repo

    end
  end
end