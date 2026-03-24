# Project Layout

Elixir library (`noizu_labs_entities`) providing entity definition macros, persistence protocols, and repo behaviours.

```
entities/
├── lib/
│   ├── noizu_labs_entities/        # Core library → [layout/lib.md](layout/lib.md)
│   │   ├── behaviours/             #   Behaviour definitions (ACL, JSON, Repo, UID)
│   │   ├── entity/                 #   Entity system (fields, identifiers, macros, meta, store)
│   │   ├── error/                  #   Shared error definitions
│   │   ├── repo/                   #   Repo macros and metadata
│   │   ├── entity.ex               #   Entity module entry point
│   │   └── repo.ex                 #   Repo module entry point
│   ├── mix/tasks/                  #   Mix task: nz.gen.entity
│   ├── helpers.ex                  #   Shared helper functions
│   └── noizu_labs_entities.ex      #   Top-level application module
├── config/                         # Mix environment configs
│   ├── config.exs                  #   Base config
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides
├── test/                           # Test suites
│   ├── support/                    #   Test fixtures and entity stubs
│   │   └── entities/               #   Sample entity definitions
│   ├── amnesia_entities_test.exs
│   ├── field_protocol_test.exs
│   ├── json_encoder_test.exs
│   └── noizu_labs_entities_test.exs
├── doc/                            # Generated ExDoc output (committed)
├── docs/                           # Project documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   └── layout/                     #   Detailed directory breakdowns
├── priv/plts/                      # Dialyzer PLT caches
├── .envrc                          # direnv — sets CODACY_PROJECT_TOKEN
├── .tool-versions                  # asdf versions: Elixir 1.19.5, Erlang 28.4
├── .formatter.exs                  # Elixir code formatter config
├── .dialyzer_ignore.exs            # Dialyzer warning suppressions
├── mix.exs                         # Project definition and dependencies
├── mix.lock                        # Locked dependency versions
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md                       # Start here
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.envrc` | Run `direnv allow` — sets `CODACY_PROJECT_TOKEN` |
| `.tool-versions` | Install runtimes via `asdf install` |
