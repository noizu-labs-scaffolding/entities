#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Repo do
  @callback __noizu_meta__() :: Map.t

  defmacro __using__(options \\ nil) do
    quote do
      require Noizu.Repo.Macros
      import Noizu.Repo.Macros, only: [{:def_repo, 0}]
      import Noizu.Core.Helpers
      import NoizuLabs.Entities.Helpers
    end
  end
end