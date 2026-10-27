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
│   ├── .credo.exs                  #   Credo static analysis config
│   ├── config.exs                  #   Base config
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides
├── test/                           # Test suites
│   ├── support/                    #   Test fixtures and entity stubs
│   │   ├── entities/               #   Sample entity definitions
│   │   ├── database.ex             #   Test database setup
│   │   ├── dummy.ex                #   Dummy modules for testing
│   │   ├── noizu_test.entity_repo.ex #  Test entity repo
│   │   └── uid_provider.ex         #   Test UID provider
│   ├── amnesia_entities_test.exs
│   ├── field_protocol_test.exs
│   ├── json_encoder_test.exs
│   ├── noizu_labs_entities_test.exs
│   ├── sref_handlers_test.exs      #   sref handler cache tests
│   ├── uid_provider_test.exs       #   UID provider tests
│   └── test_helper.exs             #   ExUnit bootstrap
├── docs/                           # Project documentation
│   ├── arch/                       #   Architecture decision records
│   │   ├── entity-dsl.md           #   Entity DSL design
│   │   ├── json-acl.md             #   JSON/ACL encoding design
│   │   └── persistence.md          #   Persistence layer design
│   ├── layout/                     #   Detailed directory breakdowns
│   │   └── lib.md
│   ├── PROJ-ARCH.md                #   Architecture overview
│   ├── PROJ-ARCH.summary.md        #   Architecture summary
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Layout summary
│   ├── PROJ-SCHEMA.md              #   Data / metadata schema reference
│   ├── PROJ-SCHEMA.summary.md      #   Schema summary
│   ├── THREAT-MODEL.md             #   Threat model and vulnerability register
│   └── THREAT-MODEL.summary.md     #   Threat model summary
├── priv/plts/                      # Dialyzer PLT caches
├── .github/workflows/ci.yml        # CI: compile + test on push/PR
├── .tool-versions                  # asdf versions (Elixir, Erlang, CMake, Node, Java)
├── .formatter.exs                  # Elixir code formatter config
├── .dialyzer_ignore.exs            # Dialyzer warning suppressions
├── .gitignore                      # Build artifacts, deps, env, agent worktrees
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
| `.tool-versions` | Install runtimes via `asdf install` |
