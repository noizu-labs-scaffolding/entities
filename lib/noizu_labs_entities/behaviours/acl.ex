# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------
defmodule Noizu.Entity.ACL.Exception do
  defexception [:details]

  def message(e) do
    "#{inspect(e.details)}"
  end
end

defprotocol Noizu.Entity.ACL.Protocol do
  @fallback_to_any true
  def restrict(for, entity, acl_settings, context, options)
end

defimpl Noizu.Entity.ACL.Protocol, for: [Any] do
  def restrict(for, entity, settings, context, options)

  def restrict(:read, entity, _, _, _) do
    {:ok, entity}
  end
end
