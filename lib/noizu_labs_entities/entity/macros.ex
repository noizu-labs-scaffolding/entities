#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Entity.Macros do
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json
  require Noizu.Entity.Meta.ACL

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
      require Noizu.Entity.Meta.ACL


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
      {vsn, nz_meta} = Noizu.Entity.Macros.inject_entity_impl(@__nz_identifiers, @__nz_fields, @__nz_json, @__nz_acl)
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
      acl = {field, field_acl} = Noizu.Entity.Macros.extract_acl(name)
      Module.put_attribute(__MODULE__, :__nz_acl, acl)
      Module.put_attribute(
        __MODULE__,
        :__nz_fields,
        {
          name,
          Noizu.Entity.Meta.Field.settings(
            name: name,
            default: default,
            pii: Noizu.Entity.Macros.extract_simple(:pii, :pii_default),
            transient: Noizu.Entity.Macros.extract_simple(:transient, :transient_default),
            acl: field_acl,
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
    Module.register_attribute(mod, :__nz_acl, accumulate: true)
    Module.register_attribute(mod, :json, accumulate: true)
    Module.register_attribute(mod, :restricted, accumulate: true)

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
  def inject_entity_impl(v__nz_identifiers, v__nz_fields, v__nz_json, v__nz_acl) do
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


    # todo this should be done in function close.
    acl = Enum.map(v__nz_acl,
      fn
        ({field, [nz: :inherit]}) ->
          with Noizu.Entity.Meta.Field.settings(transient: t, pii: p) <- nz_entity__fields[field] do
            x = cond do
              t ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :role, requirement: [:admin, :system])
              p in [:sensitive, :private] ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :role, requirement: [:user, :admin, :system])
              :else ->
                Noizu.Entity.Meta.ACL.acl_settings(target: :entity, type: :unrestricted, requirement: :unrestricted)
            end
            {field, x}
          end
        ({field, x}) -> {field, x}
    end)

    nz_meta = %{
      identifier: nz_entity__identifier,
      fields: nz_entity__fields,
      json: nz_entity__json,
      acl: acl,
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
      omit = cond do
        Noizu.Entity.Meta.Field.settings(r, :transient) == true -> true
        field == :meta -> true
        :else -> false
      end

      {field, Noizu.Entity.Meta.Json.settings(template: :default, field: field, omit: omit)}
    end)
    {de, fp} = pop_in(first_pass, [:default])
#    IO.inspect(de, label: "EXISTING DEFAULT")
    ud = Enum.map(core, fn({k,v}) ->
      {k, Noizu.Entity.Macros.merge_json_settings([v| (de[k] || [])] |> Enum.reverse() , :default, k)}
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

  # @todo implement
  def valid_path(x), do: {:ok, x}

  def valid_target(x) when x in [:entity, :field], do: {:ok, x}
  def valid_target(x), do: {:error, {:unsupported, {:target, x}}}

  @basic_types [:role, :mfa, :permission]

  # Restrict By Role
  def valid_acl(x) when is_atom(x), do: valid_acl({:role, x})
  def valid_acl({:ref, _, _} = x), do: valid_acl({:role, x})
  def valid_acl({:role, x}), do: valid_acl({:role, :entity, x})
  def valid_acl({:role, target, x}) do
    with {:ok, t} <- valid_target(target),
         true <- is_atom(x) || Kernel.match?({:ref, _, _}, x) || {:error, {:invalid, {:role, x}}} do
      s = Noizu.Entity.Meta.ACL.acl_settings(target: t, type: :role, requirement: [x])
      {:ok, s}
    end
  end

  # Restrict By Group
  def valid_acl({:group, x}), do: valid_acl({:group, :entity, x})
  def valid_acl({:group, target, x}) do
    with true <- is_atom(x) || Kernel.match?({:ref, _, _}, x) || {:error, {:invalid, {:group, x}}},
         {:ok, _} <- valid_target(target) do
      s = Noizu.Entity.Meta.ACL.acl_settings(target: target, type: :group, requirement: [x])
      {:ok, s}
    end
  end

  # Restrict By Permission
  def valid_acl({:permission, x}), do: valid_acl({:permission, :entity, x})
  def valid_acl({:permission, target, x}) do
    with true <- is_atom(x) || Kernel.match?({:ref, _, _}, x) || {:error, {:invalid, {:permission, x}}},
         {:ok, _} <- valid_target(target) do
      s = Noizu.Entity.Meta.ACL.acl_settings(target: target, type: :permission, requirement: [x])
      {:ok, s}
    end
  end

  # Restrict By MFA
  def valid_acl({m,f,a} = x) when is_atom(m) and is_atom(f) and is_list(a), do: valid_acl({:mfa, x})
  def valid_acl({:mfa, x}), do: valid_acl({:mfa, :entity, x})
  def valid_acl({:mfa, target, x}) do
    with {m,f,a} <- x,
         true <- (is_atom(m) && is_atom(f) && is_list(a)) || {:error, {:mfa, {:invalid, x}}},
         {:ok, _} <- valid_target(target) do
      s = Noizu.Entity.Meta.ACL.acl_settings(target: target, type: :mfa, requirement: [{m,f,a}])
      {:ok, s}
    end
  end

  # Target Parent
  def valid_acl({:parent, x}), do: valid_acl({:parent, 0, x})
  def valid_acl({:parent, depth, x}) when is_integer(depth) do
    case valid_acl(x) do
      [_|_] -> x
      {:ok, x} -> [{:ok, x}]
    end
    |> Enum.map(
         fn({:ok, s = Noizu.Entity.Meta.ACL.acl_settings(type: t)}) when t in [:role, :group, :mfa, :permission] ->
           s2 = Noizu.Entity.Meta.ACL.acl_settings(s, target: {:parent, depth})
           {:ok, s2}
         end)
  end

  # Target Path
  def valid_acl({:path, path, x}) do
    case valid_acl(x) do
      [_|_] -> x
      {:ok, x} -> [{:ok, x}]
    end
    |> Enum.map(
         fn({:ok, s = Noizu.Entity.Meta.ACL.acl_settings(type: t)}) when t in [:role, :group, :mfa, :permission] ->
           {:ok, p} = valid_path(path)
           s2 = Noizu.Entity.Meta.ACL.acl_settings(s, target: {:path, path})
           {:ok, s2}
         end)
  end

  # List
  def valid_acl(x) when is_list(x), do: Enum.map(x, &(valid_acl(&1))) |> List.flatten()

  # Unsupported
  def valid_acl(x), do: {:error, {:unsupported, x}}


  def merge_acl__weight(target, type) do
    target_w = case target do
      :entity -> 10
      :field -> 20
      {:parent, x} -> 50 * (x + 1)
      {:path, x} -> (50 * length(x)) + 30
    end
    type_w = case type do
      :role -> 1
      :group -> 2
      :permission -> 3
      :mfa -> 5
    end
    target_w + type_w
  end


  def merge_acl__inner([]), do: []
  def merge_acl__inner([h]), do: [h]
  def merge_acl__inner(l) when is_list(l) do
    requirements = Enum.map(l, &(Noizu.Entity.Meta.ACL.acl_settings(&1, :requirement)))
                   |> List.flatten()
    template = List.first(l)
    Noizu.Entity.Meta.ACL.acl_settings(template, requirement: requirements)
  end

  def merge_acl(x) do
    x
    |> Enum.group_by(fn(Noizu.Entity.Meta.ACL.acl_settings(target: x, type: y)) -> {x,y} end)
    |> Enum.map(&({elem(&1, 0), merge_acl__inner(elem(&1, 1))}))
    |> Enum.sort(fn({{ax,ay},_},{{bx,by},_}) ->
      a_w = merge_acl__weight(ax,ay)
      b_w = merge_acl__weight(bx,by)
      cond do
        a_w < b_w -> true
        :else -> false
      end
    end)
    |> Enum.map(&(elem(&1, 1)))
  end

  defmacro extract_acl(field) do
    quote bind_quoted: [field: field] do
      x = Module.get_attribute(__MODULE__, :restricted, [])
          |> Enum.map(&(Noizu.Entity.Macros.valid_acl(&1)))
          |> List.flatten()
          |> Enum.map(fn({:ok, x}) -> x end)
          |> case do
               [] ->
                 # if PII sensitive or than :user,
                 # if transient then :system
                 [{:nz, :inherit}]
               x when is_list(x) ->
                 x
                 |> Noizu.Entity.Macros.merge_acl()
             end
          |> List.flatten()
          |> then(&({field, &1}))
          |> tap(fn(_) -> Module.delete_attribute(__MODULE__, :restricted) end)
          #|> IO.inspect(label: "FINAL ACL")
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
        Enum.map(templates,
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
