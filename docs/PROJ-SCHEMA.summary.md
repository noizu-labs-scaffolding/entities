# Schema Summary

**noizu_labs_entities** is a library — no relational schema, no migrations, no ERD.
It defines the metadata shapes it compiles into entities/repos plus its plugin contracts.

## Configuration (`:noizu_labs_entities`)

| Key | Default | Purpose |
|-----|---------|---------|
| `:legacy_mode` | `false` | repo inference mode |
| `:uid_provider` | `Noizu.Entity.UID.Default` | UID provider module (compile-env) |
| `:uuid_lib` | `UUID` | UUID library for `Noizu.UUID` (compile-env) |
| `:umbrella` | unset | in-umbrella `noizu_labs_core` dep selection |

## Entity metadata (`__noizu_meta__/0`)

- `id_settings` — name, generate, universal, type
- `field_settings` — name, store, type, transient, pii, default, acl, options
- `persistence_settings` — table, kind, store, type
- `json_settings` — template, field, as, omit, error
- `acl_settings` — target, type, requirement

## Plugin contracts

- **UID provider** — `generate/2` → `{:ok, {id, index}}` (index `0..4095`); `ref/1`
- **Store adapters** — `EntityProtocol` + `Entity.FieldProtocol`: persist, as_record, from_record, fetch_as_entity, as_entity, merge_from_record, delete_record

Consumers own the actual persistence schema (Ecto/Mnesia/Amnesia/Redis).
