# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------
defmodule Noizu.Entity.UID do
  @moduledoc """
  Wrapper around UUID generator: to allow custom uuid generator logic.

  The provider is read at compile time from `config :noizu_labs_entities, :uid_provider`
  and defaults to `Noizu.Entity.UID.Default`. Because it is a `compile_env` value,
  changing it requires `mix deps.compile noizu_labs_entities --force`.

  A provider returns `{:ok, {id, index}}`. `id(:uuid)` identifiers hash `id` into a
  uuid5 and overwrite its last three hex digits with `index`, so `index` must be in
  `0..4095`. `id(:integer)` identifiers use `id` as-is.
  """
  @default_provider Noizu.Entity.UID.Default
  @handler Application.compile_env(:noizu_labs_entities, :uid_provider, @default_provider)
  @callback generate(any, any) :: any
  @callback ref(any) :: {:ok, any} | {:error, any}
  # ⟦𓊵𓐨𓋼𓂛⟧ generate :: auto-generated pointer for public function generate
  def generate(r, n), do: apply(@handler, :generate, [r, n])
  # ⟦𓆤𓍕𓏱𓌢⟧ ref :: auto-generated pointer for public function ref
  def ref(id), do: apply(@handler, :ref, [id])

  @doc "The provider compiled into this module."
  def provider(), do: @handler

  @doc "The provider used when `:uid_provider` is not configured."
  def default_provider(), do: @default_provider
end

defmodule Noizu.Entity.UID.Default do
  @moduledoc """
  Default `Noizu.Entity.UID` provider.

  `id` is the millisecond timestamp (offset from `epoch/0`) multiplied by 1_000_000
  plus a random 1..999_999. `index` is a per-node monotonic counter modulo 4096, so
  ids minted on one node in the same millisecond differ in their uuid suffix.

  Uniqueness across nodes is probabilistic: two ids collide only if they share the
  millisecond, the random component and the index (a birthday bound over roughly
  4e9 values per millisecond). Ordering follows the wall clock, so a clock step
  backwards can mint ids smaller than earlier ones; that does not make them collide.

  `id` fits a signed 64-bit integer until the offset passes ~9.2e12 ms (~290 years).
  """
  @behaviour Noizu.Entity.UID

  @epoch 1_683_495_051_937
  @spread 1_000_000
  @index_space 4096

  @doc "Millisecond epoch the timestamp component is offset from."
  def epoch(), do: @epoch

  @impl true
  def generate(_repo, _node) do
    ms = :os.system_time(:millisecond) - @epoch
    id = ms * @spread + :rand.uniform(@spread - 1)
    index = rem(:erlang.unique_integer([:positive, :monotonic]), @index_space)
    {:ok, {id, index}}
  end

  @impl true
  def ref(_), do: {:error, {:unsupported, __MODULE__, :ref}}
end

defmodule Noizu.Entity.UID.Stub do
  @moduledoc """
  Legacy provider (the default before 0.3.2): returns `{ms_timestamp, 0}`.

  Two entities of the same repo created in the same millisecond get the same
  `id(:uuid)`. Kept only for apps that set it explicitly.
  """
  def generate(_, _), do: {:ok, {:os.system_time(:millisecond) - 1_683_495_051_937, 0}}
  def ref(_), do: {:error, {:unsupported, __MODULE__, :ref}}
end
