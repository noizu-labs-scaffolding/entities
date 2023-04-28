#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Support.Entities.Foo do
  use Noizu.Entity
  def_entity do
    identifier :integer

    @pii :low
    field :name

    pii() do
      field :passport_number
      field :address
    end



    transient() do
      field :ephermal_one
      field :ephermal_two
    end
    @transient true
    field :ephermal_two

    field :title
    field :description



  end

end