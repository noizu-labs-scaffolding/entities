#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity.Macros do
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json

  #----------------------------------------
  # def_entity
  #----------------------------------------
  defmacro def_entity(do: block) do
    quote do
      import Noizu.Entity.Macros,
             only: [
               {:identifier, 1}, {:identifier, 2},
               {:field, 1}, {:field, 2}, {:field, 3},
               {:transient, 1},
               {:pii, 1}, {:pii, 2}
             ]
      require Noizu.Entity.Meta.Identifier
      require Noizu.Entity.Meta.Field
      require Noizu.Entity.Meta.Json

      Noizu.Entity.Macros.register_attributes(__MODULE__)

      # Set Fields
      unquote(block)

      #--------------------------
      # Default Fields
      #--------------------------
      declared = Module.get_attribute(__MODULE__, :__nz_fields, [])
      unless Noizu.Entity.Macros.field_set?(:vsn, declared) do
        field :vsn, Module.get_attribute(__MODULE__, :vsn, 1.0)
      end
      unless Noizu.Entity.Macros.field_set?(:meta, declared) do
        field :meta, nil
      end
      unless Noizu.Entity.Macros.field_set?(:__transient__, declared) do
        @transient true
        field :__transient__, nil
      end

      #--------------------------
      # Emit Struct
      #--------------------------
      Module.get_attribute(__MODULE__, :__nz_fields, [])
      |> Noizu.Entity.Macros.prepare_struct()
      |> defstruct

      #--------------------------
      # Noizu.Entity Behavior
      #--------------------------
      {vsn, nz_meta} = Noizu.Entity.Macros.inject_entity_impl(@__nz_identifiers, @__nz_fields, @__nz_json)
      @vsn vsn
      @nz_meta nz_meta
      def vsn(), do: @vsn
      def __noizu_meta__(), do: @nz_meta

    end
  end


  #==========================================================
  # def_entity macros
  #==========================================================

  #----------------------------------------
  # identifier
  #----------------------------------------
  defmacro identifier(type, opts \\ []) do
    name = opts[:name] || :identifier
    quote do
      Module.put_attribute(__MODULE__, :__nz_identifiers, {unquote(name), Noizu.Entity.Meta.Identifier.settings(name: unquote(name), type: unquote(type))})
      Module.put_attribute(__MODULE__, :__nz_fields, {unquote(name), Noizu.Entity.Meta.Field.settings(name: unquote(name), default: nil)})
    end
  end

  #----------------------------------------
  # field
  #----------------------------------------
  defmacro field(name, default \\ nil, _opts \\ []) do
    quote bind_quoted: [name: name, default: default] do
      Noizu.Entity.Macros.extract_json(name)
      Module.put_attribute(
        __MODULE__,
        :__nz_fields,
        {
          name,
          Noizu.Entity.Meta.Field.settings(
            name: name,
            default: default,
            pii: Noizu.Entity.Macros.extract_simple(:pii, :pii_default),
            transient: Noizu.Entity.Macros.extract_simple(:transient, :transient_default)
          )
        }
      )
    end
  end

  #----------------------------------------
  # transient
  #----------------------------------------
  defmacro transient(do: block) do
    quote do
      Noizu.Entity.Macros.push_attribute_queue(__MODULE__, :transient_default, :transient_default_queue, true)
      unquote(block)
      Noizu.Entity.Macros.pop_attribute_queue(__MODULE__, :transient_default, :transient_default_queue)
    end
  end

  #----------------------------------------
  # pii
  #----------------------------------------
  defmacro pii(level \\ :sensitive, do: block) do
    quote do
      Noizu.Entity.Macros.push_attribute_queue(__MODULE__, :pii_default, :pii_default_queue, unquote(level))
      unquote(block)
      Noizu.Entity.Macros.pop_attribute_queue(__MODULE__, :pii_default, :pii_default_queue)
    end
  end

  #==========================================================
  # internal macros
  #==========================================================

  #----------------------------------------
  #
  #----------------------------------------
  def push_attribute_queue(module, a_d, a_d_q, value) do
    q = [value| Module.get_attribute(module, a_d_q, [])]
    Module.put_attribute(module, a_d_q, q)
    Module.put_attribute(module, a_d, value)
  end

  #----------------------------------------
  #
  #----------------------------------------
  def pop_attribute_queue(module, a_d, a_d_q) do
    with [_|t] <- Module.get_attribute(module, a_d_q, []) do
      Module.put_attribute(module, a_d_q, t)
      with [h|_] <- t do
        Module.put_attribute(module, a_d, h)
      else
        _ ->
          Module.delete_attribute(module, a_d)
      end
    else
    _ ->
      # invalid
      Module.delete_attribute(module, a_d_q)
      Module.delete_attribute(module, a_d)
    end
  end

  #----------------------------------------
  #
  #----------------------------------------
  def register_attributes(mod) do
    Module.register_attribute(mod, :__nz_identifiers, accumulate: true)
    Module.register_attribute(mod, :__nz_fields, accumulate: true)
    Module.register_attribute(mod, :__nz_json, accumulate: true)
    Module.register_attribute(mod, :json, accumulate: true)
  end

  #----------------------------------------
  #
  #----------------------------------------
  def field_set?(field, declared_fields) do
    get_in(declared_fields, [field])
  end

  #----------------------------------------
  #
  #----------------------------------------
  def prepare_struct(fields) do
    fields
    |> Enum.map(fn({name, Noizu.Entity.Meta.Field.settings(default: dv)}) -> {name, dv} end)
    |> Enum.reverse()
  end

  #----------------------------------------
  #
  #----------------------------------------
  def inject_entity_impl(v__nz_identifiers, v__nz_fields, v__nz_json) do
    #v__nz_fields = Module.get_attribute(module, :__nz_fields, [])
    Noizu.Entity.Meta.Field.settings(default: vsn) = get_in(v__nz_fields, [:vsn])
    #Module.put_attribute(module, :vsn, vsn)

    # __noizu_meta__\0
    nz_entity__fields = Enum.reverse(v__nz_fields)
    #v__nz_identifiers = Module.get_attribute(module, :__nz_identifiers, [])
    nz_entity__identifier = (case(v__nz_identifiers) do
                               [x] -> x
                               x -> Enum.reverse(x)
                             end)
    # (Module.get_attribute(module, :__nz_json, [])
    nz_entity__json = v__nz_json
                      |> Noizu.Entity.Macros.expand_json_settings(nz_entity__fields)
    nz_meta = %{
      identifier: nz_entity__identifier,
      fields: nz_entity__fields,
      json: nz_entity__json
    }
    #Module.put_attribute(module, :nz_meta, nz_meta)
    {vsn, nz_meta}
  end

  #----------------------------------------
  #
  #----------------------------------------
  def merge_json_settings([], _, _), do: []
  def merge_json_settings([h], template, field) do
    #    h = Noizu.Entity.Meta.Json.settings(h, template: template, field: field)
    #        |> Tuple.to_list()
    #        |> Enum.map(
    #             fn
    #               (:inherit) -> nil
    #               (x) -> x
    #             end)
    #        |> List.to_tuple()
    [Noizu.Entity.Meta.Json.settings(h, template: template, field: field)]
  end
  def merge_json_settings([a,b|t], template, field) do
    #IO.inspect(%{a: a, b: b}, label: "MERGE JSON")
    h = Enum.zip(Tuple.to_list(a), Tuple.to_list(b))
        |> Enum.map(
             fn
               ({x,{:nz, :inherit}}) -> x
               ({{:nz, :inherit},x}) -> x
               ({x,_}) -> x
             end)
        |> List.to_tuple()
    merge_json_settings([h|t], template, field)
  end

  def expand_json_settings(json_list, fields) do
    # {:special, :json_template_specific2,
    #   [special: {:settings, :special, :json_template_specific2, :bop2, false, nil}]},
    #

    first_pass = json_list
                 |> Enum.group_by(&(elem(&1, 0)))
                 |> Enum.map(
                      fn({k,v}) ->
                        x = v
                            |> Enum.group_by(&(elem(&1,1)))
                            |> Enum.map(
                                 fn({k2,v2}) ->
                                   v3 = Enum.map(v2, &(elem(&1,2)))
                                        |> Enum.map(&(&1))
                                        |> List.flatten()
                                        |> Noizu.Entity.Macros.merge_json_settings(k, k2)
                                        # TODO merge
                                   {k2, v3}
                                 end)
                        {k, x}
                      end)

    core = Enum.map(fields, fn({field, r}) ->
      omit = case Noizu.Entity.Meta.Field.settings(r, :transient) do
        true -> true
        _ -> false
      end
      {field, Noizu.Entity.Meta.Json.settings(template: :default, field: field, omit: omit)}
    end)
    {de, fp} = pop_in(first_pass, [:default])
    ud = Enum.map(core, fn({k,v}) ->
      {k, Noizu.Entity.Macros.merge_json_settings([v| (de[k] || [])] |> Enum.reverse(), :default, k)}
    end)

    Enum.map([{:default, ud} | (fp || [])], fn({k, v}) ->
      v3 = Enum.map(ud, fn({k2,[v2]}) ->
        [x] = Noizu.Entity.Macros.merge_json_settings([v2| (v[k2] || [])] |> Enum.reverse(), k, k2)
        {k2, x}
      end)
           |> List.flatten()
           |> Enum.filter(&( false == Noizu.Entity.Meta.Json.settings(elem(&1, 1), :omit)))

      unless v3 == [] do
        {k, v3 |> Map.new()}
      end
    end)
    |> Enum.filter(&(&1))
    |> Map.new()
  end



  #----------------------------------------
  #
  #----------------------------------------


  #----------------------------------------
  #
  #----------------------------------------
  defmacro extract_simple(attribute, attribute_default, default \\ false) do
    quote bind_quoted: [attribute: attribute, attribute_default: attribute_default, default: default] do
      case Module.get_attribute(__MODULE__, attribute, {:attribute, :blank}) do
        {:attribute, :blank} ->
          Module.get_attribute(__MODULE__, attribute_default, default)
        x ->
          Module.delete_attribute(__MODULE__, attribute)
          x
      end
    end
  end

  def exact_json__settings(settings) do
    case settings do
      true -> [omit: false]
      :include -> [omit: false]
      false -> [omit: true]
      :omit -> [omit: true]
      {k, v2} when k in [true, false, :omit, :include] and is_list(v2) -> exact_json__settings(k) ++ exact_json__settings(v2)
      {k, v2} when k in [:omit, :include, :as] -> [{k, v2}]
      v when is_list(v) ->
        Enum.map(v, fn(x) -> exact_json__settings(x) end)
        |> List.flatten()
    end
  end

  defmacro extract_json(field) do
    quote bind_quoted: [field: field] do
      Module.get_attribute(__MODULE__, :json, [])
      |> Noizu.Entity.Macros.extract_json__inner(field)
#      |> tap(fn(x) ->
#        unless x == %{} or x == [] or x == nil do
#          Module.put_attribute(__MODULE__, :__nz_json, {field, x})
#        end
#      end)
      |> Enum.map(
           fn({template, values}) ->
             Module.put_attribute(__MODULE__, :__nz_json, {template, field, values})
           end
         )

       Module.delete_attribute(__MODULE__, :json)
    end
  end

  def extract_json__inner(json, field) do
    json
    #|> IO.inspect(label: "EXTRACT JSON 0 (#{field})")
    |> Enum.map(
      fn(entry) ->
        {t,s} = case entry do
          v when is_atom(v) -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
          [for: k, set: v] -> {k,  Noizu.Entity.Macros.exact_json__settings(v)}
          [for: k, set: v] -> {k,  Noizu.Entity.Macros.exact_json__settings(v)}
          v = [{k,v2}] ->
            cond do
              is_list(k) -> {k,  Noizu.Entity.Macros.exact_json__settings(v2)}
              k in [:omit, :include, :as] -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
              :else -> {k,  Noizu.Entity.Macros.exact_json__settings(v2)}
            end
          v when is_list(v) -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
          v ->
            {:error, [{:error, v}]}
        end

        templates = cond do
          is_list(t) -> t
          :else -> [t]
        end
        s = s
            |> Enum.reduce(
                 Noizu.Entity.Meta.Json.settings(template: nil, field: field),
                 fn({k,v}, acc) ->
                   case k do
                     :omit -> Noizu.Entity.Meta.Json.settings(acc, omit: v)
                     :include -> Noizu.Entity.Meta.Json.settings(acc, omit: !v)
                     :as -> Noizu.Entity.Meta.Json.settings(acc, as: v)
                     :error -> Noizu.Entity.Meta.Json.settings(acc, error: v)
                     _ -> acc
                   end
                 end
               )
        entries = Enum.map(templates,
                    fn(template) ->
                      Noizu.Entity.Meta.Json.settings(s, template: template)
                    end)
                  |> Enum.map(
                       fn(json_entry) ->
                         template = Noizu.Entity.Meta.Json.settings(json_entry, :template)
                         #field = Noizu.Entity.Meta.Json.settings(json_entry, :field)
                         {template, json_entry}
                       end
                     )
      end)
    |> List.flatten()
    #|> IO.inspect(label: "EXTRACT JSON 1 (#{field})")
    |> Enum.group_by(&(elem(&1, 0)))
    |> Enum.map(fn({k,v}) -> {k, Enum.map(v, &(elem(&1, 1)))}  end)
    #|> IO.inspect(label: "EXTRACT JSON 2 (#{field})")
  end


  defmacro __extract_json__(field) do
    quote do
      json = Module.get_attribute(__MODULE__, :json, [])
      # IO.inspect(json, label: "JSON STACK: #{unquote(field)}")

      Enum.map(json,
        fn(entry) ->
          {t,s} = case entry do
            v when is_atom(v) -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
            [for: k, set: v] -> {k,  Noizu.Entity.Macros.exact_json__settings(v)}
            [for: k, set: v] -> {k,  Noizu.Entity.Macros.exact_json__settings(v)}
            v = [{k,v2}] ->
              cond do
                is_list(k) -> {k,  Noizu.Entity.Macros.exact_json__settings(v2)}
                k in [:omit, :include, :as] -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
                :else -> {k,  Noizu.Entity.Macros.exact_json__settings(v2)}
              end
            v when is_list(v) -> {:default, Noizu.Entity.Macros.exact_json__settings(v)}
            v ->
              {:error, [{:error, v}]}
          end

          templates = cond do
            is_list(t) -> t
            :else -> [t]
          end
          s = s
              |> Enum.reduce(
                   Noizu.Entity.Meta.Json.settings(template: nil, field: unquote(field)),
                   fn({k,v}, acc) ->
                     case k do
                       :omit -> Noizu.Entity.Meta.Json.settings(acc, omit: v)
                       :include -> Noizu.Entity.Meta.Json.settings(acc, omit: !v)
                       :as -> Noizu.Entity.Meta.Json.settings(acc, as: v)
                       :error -> Noizu.Entity.Meta.Json.settings(acc, error: v)
                       _ -> acc
                     end
                   end
                 )
          entries = Enum.map(templates,
                      fn(template) ->
                        Noizu.Entity.Meta.Json.settings(s, template: template)
                      end)
                    |> Enum.map(
                         fn(json_entry) ->
                           template = Noizu.Entity.Meta.Json.settings(json_entry, :template)
                           field = Noizu.Entity.Meta.Json.settings(json_entry, :field)
                           Module.put_attribute(__MODULE__, :__nz_json, {template, field, json_entry})
                         end
                       )
          # IO.inspect(entries, label: "Partial Process")

        end)



      Module.delete_attribute(__MODULE__, :json)
    end
  end




end
