# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Repo.Macros do
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL

  # ----------------------------------------
  # def_repo
  # ----------------------------------------
  defmacro def_repo() do
    quote do
      require Noizu.EntityReference.Records
      alias Noizu.EntityReference.Records, as: R

      @entity __MODULE__
              |> Module.split()
              |> Enum.slice(0..-2)
              |> Module.concat()
      @poly false

      defstruct entities: [],
                length: 0,
                meta: nil,
                __transient__: nil

      # ----------------
      #
      # ----------------
      defdelegate create(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      defdelegate update(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      def get(R.ref(module: @entity) = ref, context, options) do
        with {:ok, stub} <- apply(@entity, :stub, [ref, context, options]) do
          get(stub, context, options)
        end
      end

      def get(ref, context, options) when not is_struct(ref) do
        with {:ok, ref} <- apply(@entity, :ref, [ref]),
             {:ok, stub} <- apply(@entity, :stub, [ref, context, options]) do
          get(stub, context, options)
        end
      end

      def get(entity, context, options) when is_struct(entity),
        do: Noizu.Repo.Meta.get(entity, context, options)

      # ----------------
      #
      # ----------------
      defdelegate delete(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      defdelegate __before_create__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __do_create__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __after_create__(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      defdelegate __before_update__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __do_update__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __after_update__(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      defdelegate __before_get__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __do_get__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __after_get__(entity, context, options), to: Noizu.Repo.Meta

      # ----------------
      #
      # ----------------
      defdelegate __before_delete__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __do_delete__(entity, context, options), to: Noizu.Repo.Meta
      defdelegate __after_delete__(entity, context, options), to: Noizu.Repo.Meta

      # ================================
      #
      # ================================
      defoverridable create: 3,
                     update: 3,
                     get: 3,
                     delete: 3,
                     __before_create__: 3,
                     __do_create__: 3,
                     __after_create__: 3,
                     __before_update__: 3,
                     __do_update__: 3,
                     __after_update__: 3,
                     __before_get__: 3,
                     __do_get__: 3,
                     __after_get__: 3,
                     __before_delete__: 3,
                     __do_delete__: 3,
                     __after_delete__: 3
    end
  end
end
