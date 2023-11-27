# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------
defmodule Noizu.Entity.Json.Exception do
  defexception [:details]

  def message(e) do
    "#{inspect(e.details)}"
  end
end

defprotocol Noizu.Entity.Json.Protocol do
  @fallback_to_any true
  def prep(term, settings, context, options)
end

defimpl Noizu.Entity.Json.Protocol, for: [Any] do
  @restricted :"*restricted*"
  require Noizu.Entity.Meta.Json


  def embed_field(value, field_settings, term, term_settings, context, options)

  def embed_field(value = nil, _, _, _, _, _) do
    # @todo implement embed_nil logic
    {:omit, value}
    # {:ok, value}
  end

  def embed_field(value = @restricted, _, _, _, _, _) do
    # @todo implement embed_restricted logic
    {:omit, value}
  end

  def embed_field(value = {@restricted, _}, _, _, _, _, _) do
    # @todo implement embed_restricted logic
    {:omit, value}
  end

  def embed_field(value, _, _, _, _, _) do
    {:ok, value}
  end

  def prep(term, settings, context, options)

  def prep(%{__struct__: m} = term, settings, context, options) when is_map(settings) do
    with acl_config <- Noizu.Entity.Meta.acl(m),
         {:ok, restricted} <-
           Noizu.Entity.ACL.Protocol.restrict(:read, term, acl_config, context, options) do
      Enum.map(
        settings,
        fn
          {:identifier, _} ->
            with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(term) do
              {:identifier, sref}
            else _ -> nil
            end
          {field, field_settings} ->
            with {:ok, v} <-
                   restricted
                   |> get_in([Access.key(field)])
                   |> embed_field(field_settings, term, settings, context, options),
                 {:ok, x} <- Noizu.Entity.Json.Protocol.prep(v, field_settings, context, options) do
              x
            else
              {:omit, _} -> nil
              # todo tuple error handling
              {:error, x} -> raise Noizu.Entity.Json.Exception, details: x
              x -> raise Noizu.Entity.Json.Exception, details: {:other, x}
            end
        end
      )
      |> Enum.reject(&is_nil/1)
      |> Map.new()
    else
      {:omit, _} -> nil
      x = {@restricted, _} -> x
      @restricted -> @restricted
      {:error, x} -> raise Noizu.Entity.Json.Exception, details: x
      x -> raise Noizu.Entity.Json.Exception, details: {:other, x}
    end
  end
  def prep(term, Noizu.Entity.Meta.Json.json_settings(field: f), _, _), do: {:ok, {f, term}}
end

if Code.ensure_loaded?(Poison) do
  defmodule Noizu.Entity.Json.DefaultHandler do
    def decode(_, _, _) do
      {:error, {:unsupported, :decode}}
    end

    def decode!(_, _, _) do
      raise Noizu.Entity.Json.Exception, message: :unsupported
    end

    def get_format(term, context, options)

    def get_format(_, _, _) do
      :default
    end

    def encode(%{__struct__: m} = term, context, options) do
      settings = Noizu.Entity.Meta.json(m, get_format(term, context, options))

      term
      |> Noizu.Entity.Json.Protocol.prep(settings, context, options)
      |> Poison.encode(options)
    rescue
      e in Noizu.Entity.Json.Exception -> {:error, e.details}
    end

    def encode!(%{__struct__: m} = term, context, options) do
      settings = Noizu.Entity.Meta.json(m, get_format(term, context, options))

      term
      |> Noizu.Entity.Json.Protocol.prep(settings, context, options)
      |> Poison.encode!(options)
    end
  end

  defmodule Noizu.Entity.JsonBehaviour do
    @handler Application.compile_env(
               :noizu_labs_entities,
               :json_handler,
               Noizu.Entity.Json.DefaultHandler
             )

    @callback decode(json :: any, context :: any, opts :: any) :: {:ok, any} | {:error, any}
    @callback decode!(json :: any, context :: any, opts :: any) :: any

    @callback encode(entity :: any, json_settings :: any, context :: any, opts :: any) ::
                {:ok, any} | {:error, any}
    @callback encode!(entity :: any, json_settings :: any, context :: any, opts :: any) :: any

    def decode(json, context, opts), do: apply(@handler, :decode, [json, context, opts])
    def decode!(json, context, opts), do: apply(@handler, :decode!, [json, context, opts])
    def encode(entity, context, opts), do: apply(@handler, :encode, [entity, context, opts])
    def encode!(entity, context, opts), do: apply(@handler, :encode!, [entity, context, opts])
  end
end
