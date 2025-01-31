# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2025 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.FieldProtocolTest do
  use ExUnit.Case
  require Noizu.Support.Entities.DerivedFields.DerivedFieldEntity
  require Noizu.Entity.Macros
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL
  alias Noizu.Support.Entities.DerivedFields
  alias Noizu.Support.Entities.DerivedFields.DerivedFieldEntity
  
  @context Noizu.Context.system()
  
  test "smoke test" do
    {:ok, e} = %DerivedFieldEntity{base_field_a: "anna", base_field_b: "bob"}
               |> NoizuTest.EntityRepo.create(@context)
    r = NoizuEntityTestDb.DerivedFields.DerivedFieldsTable.read!(e.id)
    {:ok, e} = DerivedFields.get(e.id, @context, [])
    fields = Noizu.Entity.Meta.fields(e)
    |> IO.inspect(label: :DEBUG)
    IO.inspect(e, label: :DEBUG)
    IO.inspect(r, label: :DEBUG)
  end

end
