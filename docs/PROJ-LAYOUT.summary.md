# Project Layout Summary

```
entities/
├── lib/
│   ├── noizu_labs_entities/
│   │   ├── behaviours/         # ACL, JSON, EntityRepo, UID behaviours
│   │   ├── entity/             # Fields, identifiers, macros, meta, store adapters
│   │   ├── error/              # Shared errors
│   │   ├── repo/               # Repo macros and meta
│   │   ├── entity.ex
│   │   └── repo.ex
│   ├── mix/tasks/              # Mix code generator
│   ├── helpers.ex
│   └── noizu_labs_entities.ex
├── config/                     # Mix configs (base, dev, test)
├── test/                       # Tests and support fixtures
├── doc/                        # Generated ExDoc
├── docs/                       # Project docs and layout
├── priv/plts/                  # Dialyzer caches
├── .envrc
├── .tool-versions
├── mix.exs
└── README.md
```
