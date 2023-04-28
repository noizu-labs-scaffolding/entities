#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity do
  @callback vsn() :: float
  @callback __entity_fields__() :: []
  @callback __entity_identifier__() :: []

  defmacro __using__(_options \\ nil) do
    quote do
      require Noizu.Entity.Meta
      import Noizu.Entity.Meta
    end
  end

  defmodule Meta do
    require Record
    Record.defrecord(:nz__field, [name: nil, type: nil, transient: false, pii: :none, default: nil])
    Record.defrecord(:nz__identifier, [name: nil, type: nil])

    defmacro def_entity(do: block) do
      quote do
        Module.register_attribute(__MODULE__, :__nz_identifiers, accumulate: true)
        Module.register_attribute(__MODULE__, :__nz_fields, accumulate: true)
        Module.register_attribute(__MODULE__, :transient, accumulate: false)
        Module.register_attribute(__MODULE__, :pii, accumulate: false)
        @pii_default false
        @transient_default false
        unquote(block)
        Noizu.Entity.Meta.__prepare_struct__()
      end
    end

    defmacro __prepare_struct__() do
      quote do
        # identifiers
        f = Module.get_attribute(__MODULE__, :__nz_fields, [])
        unless get_in(f, [:vsn]) do
          field :vsn, Module.get_attribute(__MODULE__, :vsn, 1.0)
        end
        unless get_in(f, [:meta]) do
          @transient true
          field :meta, nil
        end

        f2 = Module.get_attribute(__MODULE__, :__nz_fields, [])
             |> Enum.map(fn({name, nz__field(default: dv)}) -> {name, dv}  end)
             |> Enum.reverse()
        defstruct  f2

        nz__field(default: vsn) = get_in(@__nz_fields, [:vsn])
        @vsn vsn
        def vsn(), do: @vsn
        def __entity_fields__(), do: @__nz_fields
        def __entity_identifier__(), do: @__nz_identifiers

      end
    end

    defmacro identifier(type, opts \\ []) do
      name = opts[:name] || :identifier
      quote do
        Module.put_attribute(__MODULE__, :__nz_identifiers, {unquote(name), nz__identifier(name: unquote(name), type: unquote(type))})
        Module.put_attribute(__MODULE__, :__nz_fields, {unquote(name), nz__field(name: unquote(name), default: nil)})
      end
    end

    defmacro field(name, default \\ nil, _opts \\ []) do
      quote do
        t = case Module.get_attribute(__MODULE__, :transient, nil) do
          nil -> @transient_default
          v -> v
        end
        p = case Module.get_attribute(__MODULE__, :pii, nil) do
          nil -> @pii_default
          v -> v
        end
        Module.put_attribute(__MODULE__, :transient, nil)
        Module.put_attribute(__MODULE__, :pii, nil)
        Module.put_attribute(__MODULE__, :__nz_fields, {unquote(name), nz__field(name: unquote(name), default: unquote(default), pii: p, transient: t)})
      end
    end

    defmacro transient(do: block) do
      quote do
        @__t @transient_default
        @transient_default true
        unquote(block)
        @transient_default @__t
      end
    end


    defmacro pii(do: block) do
      quote do
        @__p @pii_default
        @pii_default :sensitive
        unquote(block)
        @pii_default @__p
      end
    end

    defmacro pii(level, do: block) do
      quote do
        @__p @pii_default
        @pii_default unquote(level)
        unquote(block)
        @pii_default @__p
      end
    end

  end

end