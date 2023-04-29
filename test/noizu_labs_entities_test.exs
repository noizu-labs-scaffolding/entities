#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EntitiesTest do
  use ExUnit.Case
  require Noizu.Support.Entities.Foo
  require Noizu.Entity.Macros
  require Noizu.Entity.Meta.Identifier
  require Noizu.Entity.Meta.Field
  require Noizu.Entity.Meta.Json

#  doctest Noizu.Entities
  def ignore_key(key, keys) do
    ks = Enum.map(keys, fn({k,_}) -> k end)
    cond do
      key in ks -> keys[key]
      :else -> :"*ignore"
    end
  end

  def expected_field(keys) do
    Noizu.Entity.Meta.Field.settings(
      name: ignore_key(:name, keys),
      type: ignore_key(:type, keys),
      transient: ignore_key(:transient, keys),
      pii: ignore_key(:pii, keys),
      default: ignore_key(:default, keys)
    )
  end

  # Record.defrecord(:nz__field, [name: nil, type: nil, transient: false, pii: false, default: nil])
  def assert_field(nil,expected) do
    assert nil == expected
  end
  def assert_field(actual,expected) do
    actual = Enum.zip(Tuple.to_list(actual), Tuple.to_list(expected))
             |> Enum.map(
                  fn
                    ({_, :"*ignore"}) -> :"*ignore"
                    ({x,_}) -> x
                  end)
             |> List.to_tuple()
    assert actual == expected
  end

  test "field attributes" do
    fields = Noizu.Entity.Meta.fields(Noizu.Support.Entities.Foo)
    assert_field(fields[:identifier], expected_field([name: :identifier, transient: false, pii: false, default: nil]))
    assert_field(fields[:name], expected_field([name: :name, transient: false, pii: :low, default: nil]))
    assert_field(fields[:passport_number], expected_field([name: :passport_number, transient: false, pii: :sensitive, default: nil]))
    assert_field(fields[:address], expected_field([name: :address, transient: false, pii: :sensitive, default: nil]))
    assert_field(fields[:ephermal_one], expected_field([name: :ephermal_one, transient: true, pii: false, default: nil]))
    assert_field(fields[:ephermal_two], expected_field([name: :ephermal_two, transient: true, pii: false, default: nil]))
    assert_field(fields[:ephermal_three], expected_field([name: :ephermal_three, transient: true, pii: false, default: nil]))
    assert_field(fields[:title], expected_field([name: :title, transient: false, pii: false, default: nil]))
    assert_field(fields[:description], expected_field([name: :description, transient: false, pii: false, default: nil]))
    assert_field(fields[:vsn], expected_field([name: :vsn, transient: false, pii: false, default: 1.0]))
    assert_field(fields[:meta], expected_field([name: :meta, transient: false, pii: false, default: nil]))
    assert_field(fields[:__transient__], expected_field([name: :__transient__, transient: true, pii: false, default: nil]))



  end

end
