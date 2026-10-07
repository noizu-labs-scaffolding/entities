Changelog
===========================

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
