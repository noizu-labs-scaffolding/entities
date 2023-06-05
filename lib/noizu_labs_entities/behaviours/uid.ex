#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Entity.UID do
  @handler Application.compile_env(:noizu_labs_entities, :uid_provider, Noizu.Entity.UID.Stub)
  @callback generate(any, any) :: any
  def generate(r,n), do: apply(@handler, :generate, [r,n])
end

defmodule Noizu.Entity.UID.Stub do
  def generate(_,_), do: {:ok, :os.system_time(:millisecond) - 1683495051937}
end