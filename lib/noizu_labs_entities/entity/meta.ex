#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.Entity.Meta do
  defmodule ACL do
    require Record
    Record.defrecord(:acl_settings, [target: nil, type: nil, requirement: nil])
  end
  defmodule Identifier do
    require Record
    Record.defrecord(:identifier_settings, [name: nil, generate: true, universal: false,  type: nil])
  end
  defmodule Field do
    require Record
    Record.defrecord(:field_settings, [name: nil, type: nil, transient: false, pii: false, default: nil, acl: nil])
  end
  defmodule Persistence do
    require Record
    Record.defrecord(:persistence_settings, [table: :auto, store: nil, type: nil])
    def ecto_store(table, store) do
      persistence_settings(table: table, store: store, type: :ecto)
    end
    def mnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: :mnesia)
    end
    def amnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: :amnesia)
    end
    def redis_store(table, store) do
      persistence_settings(table: table, store: store, type: :redis)
    end
  end
  defmodule Json do
    require Record
    Record.defrecord(:json_settings, [template: nil, field: nil, as: {:nz, :inherit}, omit: {:nz, :inherit}, error: {:nz, :inherit}])
    #Record.defrecord(:field_settings, [field: nil, settings: nil])
    #Record.defrecord(:template_field_settings, [template: nil, field_settings: nil])
  end

  @callback meta() :: []
  @callback fields() :: []
  @callback identifier() :: []
  @callback json() :: []
  @callback json(template :: atom) :: []

  def meta(m), do: m.__noizu_meta__()
  def persistence(m), do: meta(m)[:persistence]
  def identifier(m), do: meta(m)[:identifier]
  def fields(m), do: meta(m)[:fields]
  def json(m), do: meta(m)[:json]
  def json(m, s) do
    meta = meta(m)
    json = meta[:json]
    json[s] || json[:default]
  end
  def acl(m), do: meta(m)[:acl]


  defmacro __using__(_options \\ nil) do
    quote do
      require Noizu.Entity.Meta.Identifier
      require Noizu.Entity.Meta.Field
      require Noizu.Entity.Meta.Json
      alias Noizu.Entity.Meta
    end
  end

end