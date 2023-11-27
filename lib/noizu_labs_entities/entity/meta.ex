# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entity.Meta do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  defmodule ACL do
    require Record
    Record.defrecord(:acl_settings, target: nil, type: nil, requirement: nil)
  end

  defmodule Identifier do
    require Record
    Record.defrecord(:identifier_settings, name: nil, generate: true, universal: false, type: nil)
  end

  defmodule Field do
    require Record
    Record.defrecord(:field_settings,
      name: nil,
      store: [],
      type: nil,
      transient: false,
      pii: false,
      default: nil,
      acl: nil,
      options: nil
    )
  end

  defmodule Persistence do
    require Record
    Record.defrecord(:persistence_settings, table: :auto, kind: nil, store: nil, type: nil)

    def by_table(module, table) do
      Enum.find_value(
        Noizu.Entity.Meta.persistence(module),
        fn
          settings = persistence_settings(table: ^table) -> {:ok, settings}
          _ -> nil
        end
      ) || {:error, :not_found}
    end

    def by_type(module, type) do
      Enum.find_value(
        Noizu.Entity.Meta.persistence(module),
        fn
          settings = persistence_settings(type: ^type) -> {:ok, settings}
          _ -> nil
        end
      ) || {:error, :not_found}
    end

    def by_store(module, store) do
      Enum.find_value(
        Noizu.Entity.Meta.persistence(module),
        fn
          settings = persistence_settings(store: ^store) -> {:ok, settings}
          _ -> nil
        end
      ) || {:error, :not_found}
    end

    def ecto_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Ecto)
    end

    def mnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Mnesia)
    end

    def amnesia_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Amnesia)
    end

    def redis_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Redis)
    end

    def dummy_store(table, store) do
      persistence_settings(table: table, store: store, type: Noizu.Entity.Store.Dummy)
    end
  end

  defmodule Json do
    require Record

    Record.defrecord(:json_settings,
      template: nil,
      field: nil,
      as: {:nz, :inherit},
      omit: {:nz, :inherit},
      error: {:nz, :inherit}
    )

    # Record.defrecord(:field_settings, [field: nil, settings: nil])
    # Record.defrecord(:template_field_settings, [template: nil, field_settings: nil])
  end

  @callback meta() :: []
  @callback fields() :: []
  @callback identifier() :: []
  @callback persistence() :: []
  @callback json() :: []
  @callback json(template :: atom) :: []

  # ---------------
  #
  # ---------------
  def meta(%{__struct__: m}), do: meta(m)
  def meta(R.ref(module: m)), do: meta(m)
  def meta(m) when is_atom(m) do
    apply(m, :__noizu_meta__, [])
    rescue _ -> nil
  end

  def meta(m),
    do:
      raise(Noizu.EntityReference.ProtocolException,
        ref: m,
        message: "Invalid Entity",
        error: :invalid
      )

  # ---------------
  #
  # ---------------
  def sref(m), do: meta(m)[:sref]

  # ---------------
  #
  # ---------------
  def persistence(m), do: meta(m)[:persistence]

  # ---------------
  #
  # ---------------
  def repo(m), do: meta(m)[:repo]

  # ---------------
  #
  # ---------------
  def identifier(m), do: meta(m)[:identifier]

  # ---------------
  #
  # ---------------
  def fields(m), do: meta(m)[:fields]

  # ---------------
  #
  # ---------------
  def json(m), do: meta(m)[:json]

  # ---------------
  #
  # ---------------
  def json(m, s) do
    meta = meta(m)
    json = meta[:json]
    json[s] || json[:default]
  end

  # ---------------
  #
  # ---------------
  def acl(m), do: meta(m)[:acl]

  # ---------------
  #
  # ---------------

  # ---------------
  #
  # ---------------
  defmacro __using__(_options \\ nil) do
    quote do
      require Noizu.Entity.Meta.Identifier
      require Noizu.Entity.Meta.Field
      require Noizu.Entity.Meta.Json
      alias Noizu.Entity.Meta
    end
  end
end
