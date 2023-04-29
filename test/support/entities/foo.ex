#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Support.Entities.Foo do
  use Noizu.Entity
  def_entity do
    identifier :integer

    @restricted :user
    @restricted {:role, :supper_trooper}
    @restricted {:role, :field, :supper_trooper}
    @restricted [{:role, :role2}, {:role, :role3}]
    @restricted [{:parent, :user}]
    @restricted [{:path, [{Access, :key, [:a]}, {Access, :key, [:b]}], {:role, :role_x}}]
    @restricted [{:path, [{Access, :key, [:a]}, {Access, :key, [:b]}], {:role, :role_y}}]
    @pii :low
    field :name

    pii() do
      @json false
      field :passport_number
      field :address
    end



    transient() do
      @json admin: true
      field :ephermal_one
      @json false
      field :ephermal_two
    end
    @transient true
    field :ephermal_three

    @json brief: false
    field :title

    @json :omit
    @json admin: true
    @json for: [:admin, :admin2], set: [as: :ignore]
    @json admin: [as: :apple]
    field :title2


    @json false
    @json admin: true
    field :description

    @json false
    @json for: [:admin, :api, :brief], set: true
    @json for: [:foo, :bar], set: [true, as: :fop]
    @json for: :special, set: [omit: false, as: :bop]
    @json for: :api, set: [omit: true, as: :bop2]
    field :json_template_specific

    @json false
    @json for: [:admin, :api, :brief], set: true
    @json for: [:foo, :bar], set: [true, as: :fop2]
    @json for: :api, set: [omit: false, as: :bop2]
    field :json_template_specific2


  end

end