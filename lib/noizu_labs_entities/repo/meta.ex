#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Repo.Meta do


  def create(entity) do
    IO.puts "ITERATE OVER PERSISTENCE LAYERS AND PERSIST"
    {:ok, entity}
  end

  def as_record(entity, record) do
    IO.inspect "TODO as record"
    {:ok, entity}
  end

end