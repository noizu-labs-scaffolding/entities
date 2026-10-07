Changelog
===========================

## 0.3.4

0.3.3 was tagged but never published to hex; 0.3.4 supersedes it and ships its
fixes (see 0.3.3 below): lowercase uuid tail (ids round-trip through Postgres),
counter-bucket `UID.Default` (no same-node `{id, index}` repeats below
4_096_000 ids/ms), and downcasing of string ids on parse.

### Fixes

- fix: `sref_handlers/0` returned `%{}` to concurrent first callers. The table was
  built lazily behind a non-blocking 1-slot `Semaphore.acquire/2`; every caller
  that lost the race while the first build ran (seconds in large apps) got an
  empty map, so sref lookups failed with `handler_not_found` (e.g. Guardian 401s
  right after pod boot, and in test runs not preloaded by `--cover`). Callers that
  find no cached table now build it themselves (idempotent) and the first finished
  build is published to `:persistent_term`; an empty map is never returned while
  a build is pending. Table contents and shape are unchanged. The lock key was
  also global across repos, and the library never declared `:semaphore` as a
  dependency; both are gone.
- New `warm_sref_handlers/0` on repos using `Noizu.EntityRepoBehaviour`: call it
  in `Application.start/2` to pay the cold build at boot.

## 0.3.3 (tagged, never published to hex)

### Fixes

- fix: 0.3.2 minted uppercase hex in the uuid tail; ids did not round-trip.
  `id(:uuid)` ids end in the provider `index` as three hex digits, which
  `Integer.to_string/2` renders uppercase. Postgres (via `Ecto.UUID`) returns
  lowercase, so for any index containing a-f the id an entity was created with
  differed from the id read back (`created.id != fetched.id`). The tail is now
  lowercase. `uuid` columns are unaffected (they store bytes) and srefs are
  case-insensitive (ShortUUID). `UUIDIdentifier.id/2` and `uuid_string/1` now
  downcase string ids, so a legacy uppercase id read from a text column resolves
  to the canonical form; raw string comparisons in app code are not normalized.
- `Noizu.Entity.UID.Default`: same-node ids no longer rely on randomness to stay
  unique. The thousands of the id now carry the monotonic counter's bucket
  (`div(counter, 4096)` modulo 1000) and the random part is 1..999, so a node only
  repeats an `{id, index}` pair after 4_096_000 ids in one millisecond. 0.3.2 could
  repeat after 4096 (seen as an intermittent failure of its own 50k-id uniqueness
  test under concurrent load). Cross-node bound unchanged (~4e9 per millisecond).

## 0.3.2

### Behaviour change: default UID provider

- `Noizu.Entity.UID` now falls back to the new `Noizu.Entity.UID.Default` when
  `config :noizu_labs_entities, :uid_provider` is not set. It was
  `Noizu.Entity.UID.Stub`, which returned `{ms_timestamp, 0}`: two `id(:uuid)`
  entities of the same repo created in the same millisecond got the same primary
  key.
- `Default` returns `{ms_offset * 1_000_000 + rand(1..999_999), index}`, where
  `index` is a per-node monotonic counter modulo 4096. Ids stay time-ordered at
  millisecond granularity (by wall clock), fit a signed 64-bit integer, and are
  always larger than ids the stub minted, so they cannot clash with rows created
  under the stub. Cross-node uniqueness is probabilistic (birthday bound over
  ~4e9 values per millisecond).
- `Noizu.Entity.UID.Stub` is kept for apps that configure it explicitly. Apps
  that configure their own provider are unaffected.
- Added `Noizu.Entity.UID.provider/0` and `default_provider/0`.

**Upgrade:** `:uid_provider` is read with `Application.compile_env`, so existing
checkouts must recompile the dependency after updating:

```
mix deps.update noizu_labs_entities
mix deps.compile noizu_labs_entities --force
```

Apps that copied the per-app provider (e.g. `config :noizu_labs_entities,
uid_provider: MyApp.EntityUID`) can drop the module and the config line.
