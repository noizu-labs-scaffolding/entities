# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------


defmodule Noizu.Support.Entities.NestedFields do
  use Noizu.Repo
  def_repo(
  entity: Noizu.Support.Entities.NestedFields.NestedField
  )
end

defmodule Noizu.Support.Entities.NestedFields.NestedField do
  use Noizu.Entity
  
  @vsn 1.0
  @sref "nested-field"
  @persistence amnesia_store(NoizuEntityTestDb.NestedFields.NestedFieldTable, NoizuTest.EntityRepo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
  end
end

defmodule Noizu.Support.Entities.NestedFields.NestedFieldReference do
  use Noizu.Entity.ReferenceBehaviour,
      identifier_type: :uuid,
      entity: Noizu.Support.Entities.NestedFields.NestedField
end
