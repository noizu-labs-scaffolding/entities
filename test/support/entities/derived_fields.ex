# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------


defmodule Noizu.Support.Entities.DerivedFields do
  use Noizu.Repo
  def_repo(
  entity: Noizu.Support.Entities.DerivedFields.DerivedFieldEntity
  )
end

defmodule Noizu.Support.Entities.DerivedFields.DerivedFieldEntity do
  use Noizu.Entity
  
  
  @vsn 1.0
  @sref "derived-field-entity"
  @persistence amnesia_store(NoizuEntityTestDb.DerivedFields.DerivedFieldsTable, NoizuTest.EntityRepo)
  def_entity do
    id(:integer)
    
    @config pull: &__MODULE__.pull_derived_field/4, push: &__MODULE__.push_derived_field/5
    field :derived_field_a, nil, Noizu.Entity.DerivedField
    field :base_field_a, nil, :string
    field :base_field_b, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  
  end
  
  
  def push_derived_field(field, Noizu.Entity.Meta.Field.field_settings(
    name: name,
    store: field_store,
    options: field_options
  ) = field_settings, Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table) =
    persistence_settings, context, options) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    
    {:ok, {as_name, field}}
  end
  def pull_derived_field(as_name, record, context, field_options) do
    {:ok, "der-#{record.entity.base_field_a}-#{record.entity.base_field_b}"}
  end
  
  
  # todo  REPO - own module
  # todo  all entity to pl logic
  # todo  ref, entity, id, -> Noizu.Entity.ref(module, ref, options) -> injected by derive with macro callback.
end
