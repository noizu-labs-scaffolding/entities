# AGENT-README

> Orientation for AI coding agents working in this repo. Human docs: README.md.

## Type

elixir-lib

## Purpose

Noizu entity scaffolding: Elixir structs with metadata for access control, sensitive-data flagging, JSON formatting, text/geo/vector indexing, and per-entity caching; standardized ORM mapping across ecto, mnesia, redis and other persistence layers with layered cache/persistence support.

## Stack

Elixir (~> 1.14). Deps: ecto_sql, noizu_labs_core, nuamnesia (optional), shortuuid, inflex28, elixir_uuid (optional); mimic + junit_formatter for test; credo + dialyxir for dev. Hex app `:noizu_labs_entities` v0.3.4.

## Dev mode

```bash
mix deps.get && mix compile
```

## Ports / URLs

- none (library/CLI)

## Tests

```bash
mix test
```

## Gotchas

- `config :noizu_labs_entities, legacy_mode: false` is set in `config/config.exs`.
- The `noizu_labs_core` dep switches to an in-umbrella dep when `Application.get_env(:noizu_labs_entities, :umbrella)` is true (`mix.exs`).
- Dialyzer PLT lives at `priv/plts/project.plt`; `lib/mix/tasks/*` are excluded from dialyzer.
- Test coverage threshold is 40% (`mix.exs`).
