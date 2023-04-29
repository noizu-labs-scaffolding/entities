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

  def expected_json(keys) do
    Noizu.Entity.Meta.Json.settings(
      template: ignore_key(:template, keys),
      field: ignore_key(:field, keys),
      as: ignore_key(:as, keys),
      omit: ignore_key(:omit, keys),
      error: ignore_key(:error, keys)
    )
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
  def assert_record(actual = nil, expected) do
    assert actual == expected
  end
  def assert_record(actual, expected = nil) do
    assert actual == expected
  end
  def assert_record(actual,expected) do
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
    assert_record(fields[:identifier], expected_field([name: :identifier, transient: false, pii: false, default: nil]))
    assert_record(fields[:name], expected_field([name: :name, transient: false, pii: :low, default: nil]))
    assert_record(fields[:passport_number], expected_field([name: :passport_number, transient: false, pii: :sensitive, default: nil]))
    assert_record(fields[:address], expected_field([name: :address, transient: false, pii: :sensitive, default: nil]))
    assert_record(fields[:ephermal_one], expected_field([name: :ephermal_one, transient: true, pii: false, default: nil]))
    assert_record(fields[:ephermal_two], expected_field([name: :ephermal_two, transient: true, pii: false, default: nil]))
    assert_record(fields[:ephermal_three], expected_field([name: :ephermal_three, transient: true, pii: false, default: nil]))
    assert_record(fields[:title], expected_field([name: :title, transient: false, pii: false, default: nil]))
    assert_record(fields[:description], expected_field([name: :description, transient: false, pii: false, default: nil]))
    assert_record(fields[:vsn], expected_field([name: :vsn, transient: false, pii: false, default: 1.0]))
    assert_record(fields[:meta], expected_field([name: :meta, transient: false, pii: false, default: nil]))
    assert_record(fields[:__transient__], expected_field([name: :__transient__, transient: true, pii: false, default: nil]))
  end

  describe "Entity Json" do
    test "templates" do
      templates  = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo)
      |> Map.keys
      assert templates == [:admin, :admin2, :api, :bar, :brief, :default, :foo, :special]
    end

    test "not_set template" do
      unsupported  = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, :not_supported)
      default = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, :default)
      assert unsupported == default
    end

    test "default template" do
      template = :default
      sut = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, template)
      assert_record(sut[:name], expected_json([field: :name, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))

      assert_record(sut[:passport_number], nil)
      assert_record(sut[:address], expected_json([field: :address, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))

      # :admin
      #assert_record(sut[:ephermal_one], expected_json([field: :ephermal_one, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:ephermal_one], nil)
      assert_record(sut[:ephermal_two], nil)
      assert_record(sut[:ephermal_three], nil)

      assert_record(sut[:title], expected_json([field: :title, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))

      # :admin
      # assert_record(sut[:title2], expected_json([field: :title2, template: template, omit: false, as: :apple, error: {:nz, :inherit}]))
      # :admin2
      # assert_record(sut[:title2], nil) # Error
      assert_record(sut[:title2], nil)

      # :admin
      # assert_record(sut[:description], expected_json([field: :description, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:description], nil)

      # :admin, :api, :brief  todo add as: directive to :api
      # assert_record(sut[:json_template_specific], expected_json([field: :json_template_specific, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:json_template_specific], nil)

      # :admin, :api, :brief  todo add as: directive to :api
      # assert_record(sut[:json_template_specific2], expected_json([field: :json_template_specific2, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))

      assert_record(sut[:json_template_specific2], nil)

    end

    test "admin template" do
      template = :admin
      sut = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, template)
      assert_record(sut[:name], expected_json([field: :name, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:passport_number], nil)
      assert_record(sut[:address], expected_json([field: :address, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:ephermal_one], expected_json([field: :ephermal_one, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:ephermal_two], nil)
      assert_record(sut[:ephermal_three], nil)
      assert_record(sut[:title], expected_json([field: :title, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:title2], expected_json([field: :title2, template: template, omit: false, as: :apple, error: {:nz, :inherit}]))
      assert_record(sut[:description], expected_json([field: :description, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:json_template_specific], expected_json([field: :json_template_specific, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:json_template_specific2], expected_json([field: :json_template_specific2, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
    end

    test "api template" do
      template = :api
      sut = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, template)
      assert_record(sut[:name], expected_json([field: :name, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:passport_number], nil)
      assert_record(sut[:address], expected_json([field: :address, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:ephermal_one], nil)
      assert_record(sut[:ephermal_two], nil)
      assert_record(sut[:ephermal_three], nil)
      assert_record(sut[:title], expected_json([field: :title, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:title2], nil)
      assert_record(sut[:description], nil)
      assert_record(sut[:json_template_specific], nil)
      assert_record(sut[:json_template_specific2], expected_json([field: :json_template_specific2, template: template, omit: false, as: :bop2, error: {:nz, :inherit}]))
    end

    test "brief template" do
      template = :brief
      sut = Noizu.Entity.Meta.json(Noizu.Support.Entities.Foo, template)
      assert_record(sut[:name], expected_json([field: :name, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:passport_number], nil)
      assert_record(sut[:address], expected_json([field: :address, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:ephermal_one], nil)
      assert_record(sut[:ephermal_two], nil)
      assert_record(sut[:ephermal_three], nil)
      assert_record(sut[:title], nil)
      assert_record(sut[:title2], nil)
      assert_record(sut[:description], nil)
      assert_record(sut[:json_template_specific], expected_json([field: :json_template_specific, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
      assert_record(sut[:json_template_specific2], expected_json([field: :json_template_specific2, template: template, omit: false, as: {:nz, :inherit}, error: {:nz, :inherit}]))
    end

  end
end
