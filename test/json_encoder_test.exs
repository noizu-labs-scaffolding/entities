# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.JasonEncoderTest do
  use ExUnit.Case
  require Noizu.Support.Entities.Foos.Foo
  require Noizu.Entity.Macros
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL

  @context Noizu.Context.system()

  test "Happy Path" do
    {:ok, e} = %Noizu.Support.Entities.BizBops.BizBop{title2: "Apple", description: "Bop", created_on: DateTime.utc_now()}
               |> NoizuTest.EntityRepo.create(@context)
    json =  Jason.encode(e, user: [context: @context, options: []])
    assert json == {:ok,
             "{\"created_on\":\"#{e.created_on |> DateTime.to_iso8601}\",\"identifier\":\"ref.biz-bop.#{ShortUUID.encode!(e.identifier)}\",\"vsn\":1.0}"}
  end

end
