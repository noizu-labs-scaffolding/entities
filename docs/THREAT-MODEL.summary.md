# Threat Model Summary

**noizu_labs_entities** is a compile-time code-gen + serialization library with no
network surface. Its security-relevant surface is the code it injects and the
data-boundary decisions it makes for the host app.

## Crown jewels

1. Field-level ACL during JSON serialization
2. PII / transient classification metadata
3. Identifier generation (uniqueness underpins record identity)

## Trust boundaries

- Build host → compiled module (compile-time macro expansion; supply chain)
- Host app → serialized output (ACL must hold here)
- Host app → store adapters (consumer-supplied credentials)

## Register

| ID | Severity | STRIDE | Component | Status |
|----|----------|--------|-----------|--------|
| T-001 | High | Info disclosure | Default ACL `Any` passes all fields | Partial (consumer discipline) |
| T-002 | Medium | Info disclosure | ACL opt-in per entity; unruled `transient`/`pii` fields leak | Partial |
| T-003 | Medium | Spoofing | UID `index` must be `0..4095` | Mitigated by contract |
| T-004 | Low | Spoofing | `UID.Stub` collides within a millisecond | Accepted (legacy opt-in) |
| T-005 | Low | Tampering | sref→module table from app module scan | Mitigated (one module per sref, cached) |
| T-006 | Medium | Elevation | Compile-time macros run developer code | Accepted (hex supply chain) |
| T-007 | Low | Info disclosure | Bypassing `prep/4` skips ACL | Mitigated (generated encoder) |

## Residual risk

Fail-open serialization (T-001/T-002) is the dominant risk: the default ACL impl
returns `{:ok, entity}` for `:read`, so PII/transient fields are only redacted
when the host provides a restricting `ACL.Protocol` implementation. Accepted —
the library cannot know a host's role model.
