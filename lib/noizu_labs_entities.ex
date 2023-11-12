# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entities do
  defmacro __using__(options \\ nil) do
    quote do
      require Logger
      require Record
      use Noizu.Entity.Meta, unquote(options)
      alias Noizu.Service.Types, as: M
      alias Noizu.Service.Types.Handle, as: MessageHandler
      require Noizu.EntityReference.Records
      alias Noizu.EntityReference.Records, as: R
      alias Noizu.EntityReference.Protocol, as: ERP

      Module.register_attribute(__MODULE__, :persistence, accumulate: true)
      Module.register_attribute(__MODULE__, :vsn, accumulate: false)
      Module.register_attribute(__MODULE__, :sref, accumulate: false)

      use Noizu.Entity
      use Noizu.Repo
    end
  end
end
