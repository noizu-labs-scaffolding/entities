# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2026 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.EntityRepoBehaviour.SrefHandlersTest do
  # Clears a persistent_term the repo caches, so it must not overlap other tests.
  use ExUnit.Case,
    async: false

  defmodule Repo do
    use Noizu.EntityRepoBehaviour,
      application: :noizu_labs_entities,
      module: Noizu.Support.Entities
  end

  @callers 50

  defp clear(), do: :persistent_term.erase({Repo, :handlers})

  defp expected() do
    handlers = Repo.rebuild_sref_handlers()
    assert map_size(handlers) > 0
    handlers
  end

  # 0.3.3 and earlier: callers that lost a non-blocking 1-slot semaphore while the
  # first caller was building got %{} (handler_not_found -> e.g. Guardian 401).
  test "concurrent first calls all get the full handler table" do
    expected = expected()

    for _ <- 1..20 do
      clear()

      results =
        1..@callers
        |> Task.async_stream(fn _ -> Repo.sref_handlers() end,
          max_concurrency: @callers,
          timeout: 30_000
        )
        |> Enum.map(fn {:ok, handlers} -> handlers end)

      assert Enum.all?(results, &(&1 == expected)),
             "#{Enum.count(results, &(&1 != expected))}/#{@callers} callers got #{inspect(Enum.find(results, &(&1 != expected)))}"
    end
  end

  test "warm_sref_handlers/0 builds the table eagerly" do
    expected = expected()
    clear()

    assert :ok == Repo.warm_sref_handlers()
    assert :persistent_term.get({Repo, :handlers}) == expected
    assert Repo.sref_handlers() == expected
  end
end
