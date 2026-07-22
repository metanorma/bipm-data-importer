# 17 — Typed domain models (future)

## Problem
Both sides of the YAML schema are untyped:
- **Producer** (`Common.parse_resolution`, `CGPM.parse_resolution`, `exe/bipm-fetch`) returns/accumulates string-keyed hashes.
- **Consumer** (`Outcomes::Resolution#document`, etc.) indexes into those hashes by string keys.

Neither side declares the schema. Renaming `metadata/title` → `metadata/name` requires touching 5+ files. The implicit schema drifts silently.

## Fix
Introduce `lutaml-model` models:
- `Bipm::Data::Outcomes::Models::Meeting` (serializes to/from the YAML shape)
- `Bipm::Data::Outcomes::Models::Resolution`
- `Bipm::Data::Outcomes::Models::Consideration`, `Action`, `Approval`

Per user rule (CLAUDE.md), no hand-rolled `to_h`/`from_h`. Use `lutaml-model` attribute declarations + `mapping do ... end`.

Producer side constructs instances; serializes via `lutaml-model`.
Consumer side deserializes via `Model.from_hash(YAML.load_file(...))`.

## Why deferred
- Requires adding `lutaml-model` as a runtime dependency.
- The current hash-based producer is well-tested via the existing data-shape specs; changing the producer is risky.
- Better as a separate PR after Phase 1–5 land and stabilize.

## Acceptance (when done)
- `grep -rn "document\\[\\\"" lib/bipm/data/outcomes/` → empty.
- `grep -rn "def to_h\\|def from_h\\|def to_hash" lib/bipm/data/outcomes/` → empty.
- YAML output unchanged (verified by diffing `data/` before/after).

## Status
Deferred. Tracked here so it's not forgotten.
