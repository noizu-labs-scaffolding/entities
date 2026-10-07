# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2026 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entity.UID.DefaultTest do
  use ExUnit.Case,
    async: true

  alias Noizu.Entity.UID.Default
  alias Noizu.Support.Entities.BizBops.BizBop

  @tasks 50
  @per_task 1_000
  @max_bigint 9_223_372_036_854_775_807

  # Mint @tasks x @per_task ids concurrently and return {id, index} pairs.
  defp mint(provider) do
    1..@tasks
    |> Task.async_stream(
      fn _ ->
        for _ <- 1..@per_task do
          {:ok, pair} = provider.generate(Noizu.Support.Entities.BizBops, node())
          pair
        end
      end,
      max_concurrency: @tasks,
      timeout: 30_000
    )
    |> Enum.flat_map(fn {:ok, pairs} -> pairs end)
  end

  defp format_uuid({id, index}),
    do: Noizu.Entity.Meta.UUIDIdentifier.format_id(%BizBop{}, id, index)

  describe "generate/2" do
    test "concurrent ids are unique as id(:uuid) primary keys" do
      pairs = mint(Default)
      uuids = Enum.map(pairs, &format_uuid/1)

      assert length(pairs) == @tasks * @per_task
      assert length(Enum.uniq(pairs)) == length(pairs)
      assert length(Enum.uniq(uuids)) == length(uuids)
    end

    test "ids fit the existing columns" do
      for {id, index} = pair <- mint(Default) |> Enum.take_random(2_000) do
        assert is_integer(id) and id > 0 and id <= @max_bigint
        assert index in 0..4095
        assert {:ok, _} = Ecto.UUID.cast(format_uuid(pair))
      end
    end

    # Postgres stores uuid columns as 16 bytes and Ecto loads them back as
    # lowercase hex; an id that is not already in that form changes on the
    # round trip, so `created.id != fetched.id` (0.3.2 minted an uppercase tail).
    test "formatted uuids round-trip unchanged for every index, including a-f" do
      for index <- [0x00A, 0x0BC, 0xDEF, 0xFFF | Enum.to_list(0..4095//97)] do
        uuid = format_uuid({123_456_789, index})
        {:ok, raw} = Ecto.UUID.dump(uuid)

        assert uuid == String.downcase(uuid)
        assert uuid == Ecto.UUID.load(raw) |> elem(1)
        assert uuid == Ecto.UUID.cast!(uuid)

        assert String.ends_with?(
                 uuid,
                 index |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(3, "0")
               )
      end
    end

    test "legacy uppercase-tail ids (0.3.2) normalize to the canonical form" do
      legacy = "8277069e-de6e-58b5-9b9f-d43f50f5aABC"
      canonical = String.downcase(legacy)

      assert {:ok, ^canonical} = Noizu.Entity.Meta.UUIDIdentifier.id(BizBop, legacy)
      assert Noizu.Entity.Meta.UUIDIdentifier.uuid_string(legacy) == canonical
      # srefs go through ShortUUID, which is already case-insensitive.
      assert ShortUUID.encode!(legacy) == ShortUUID.encode!(canonical)
    end

    test "default-minted uuids are already canonical" do
      for pair <- mint(Default) |> Enum.take_random(2_000) do
        uuid = format_uuid(pair)
        {:ok, raw} = Ecto.UUID.dump(uuid)
        assert {:ok, ^uuid} = Ecto.UUID.load(raw)
      end
    end

    test "ids are newer than any id the stub minted" do
      {:ok, {stub_id, 0}} = Noizu.Entity.UID.Stub.generate(nil, node())
      {:ok, {id, _}} = Default.generate(nil, node())

      assert id > stub_id
      assert div(id, 1_000_000) >= stub_id
    end

    # Negative control: the same check must fail for the legacy stub, or the
    # uniqueness test above proves nothing.
    test "the legacy stub collides under the same load" do
      uuids = Noizu.Entity.UID.Stub |> mint() |> Enum.map(&format_uuid/1)
      assert length(Enum.uniq(uuids)) < length(uuids)
    end
  end
end

defmodule Noizu.Entity.UID.SerialTest do
  # Recompiles Noizu.Entity.UID and samples a VM-wide counter, so it must not
  # overlap async tests.
  use ExUnit.Case,
    async: false

  @source Path.expand("../lib/noizu_labs_entities/behaviours/uid.ex", __DIR__)

  # Dynamic call: the type checker pins provider/0 to the module compiled at load.
  defp provider(), do: apply(Noizu.Entity.UID, :provider, [])

  defp recompile() do
    ignore = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)

    try do
      Code.compile_file(@source)
    after
      Code.put_compiler_option(:ignore_module_conflict, ignore)
    end
  end

  test "Default is used when :uid_provider is not configured" do
    configured = Application.fetch_env!(:noizu_labs_entities, :uid_provider)
    assert provider() == configured

    try do
      Application.delete_env(:noizu_labs_entities, :uid_provider)
      recompile()

      assert provider() == Noizu.Entity.UID.Default
      assert Noizu.Entity.UID.default_provider() == Noizu.Entity.UID.Default
      assert {:ok, {_, _}} = Noizu.Entity.UID.generate(nil, node())
    after
      Application.put_env(:noizu_labs_entities, :uid_provider, configured)
      recompile()
    end

    assert provider() == configured
  end

  # Runs here, not with the async tests: :erlang.unique_integer/1 is VM-wide, so
  # concurrent minting could advance it by a multiple of 4096 between samples.
  test "index is monotonic within a node" do
    indexes =
      for _ <- 1..100, do: elem(elem(Noizu.Entity.UID.Default.generate(nil, node()), 1), 1)

    steps =
      indexes
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> rem(b - a + 4096, 4096) end)

    assert Enum.all?(steps, &(&1 > 0))
  end
end
