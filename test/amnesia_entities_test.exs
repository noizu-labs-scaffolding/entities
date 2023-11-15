# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.AmnesiaEntitiesTest do
  use ExUnit.Case
  require Noizu.Support.Entities.Foo
  require Noizu.Entity.Macros
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL

  @context Noizu.Context.system()

  test "smoke test" do
    {:ok, e} = %Noizu.Support.Entities.BizBopEntity{title2: "Apple", description: "Bop", created_on: DateTime.utc_now()}
               |> NoizuTest.EntityRepo.create(@context)
    r = NoizuEntityTestDb.BizBopTable.read!(e.identifier)
    assert is_integer(r.created_on)
    fields = Noizu.Entity.Meta.fields(e)
    Noizu.Entity.Meta.Field.field_settings(options: o) = fields[:title2]
    assert o == [auto: false]
  end

end
