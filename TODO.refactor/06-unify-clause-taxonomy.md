# 06 — Unify clause taxonomy

## Problem
Three parallel taxonomies of the same domain concept (a natural-language verb → an outcome type):

1. `lib/bipm/data/importer/common.rb:25-44` — `CONSIDERATIONS` (regex → type)
2. `lib/bipm/data/importer/common.rb:46-87` — `ACTIONS` (regex → type)
3. `lib/bipm/data/importer/cgpm.rb:28-38` — `CONSIDERATION_VERBS`, `ACTION_VERBS` (verb arrays)
4. `lib/bipm/data/importer/cgpm.rb:40-87` — `FR_VERB_TO_EN` (verb → English verb)
5. `lib/bipm/data/importer/cgpm.rb:89-135` — `VERB_TO_TYPE` (English verb → type)

Each has different French coverage and different fallback semantics. They drift silently. Adding a new verb requires touching 5 places.

## Fix
Introduce a single `Bipm::Data::Importer::Clauses` module that owns:

- `TYPES` — frozen set of canonical types (`considering`, `noting`, `decides`, etc.).
- `VERBS` — table of `{verb => {type:, regex:}}` covering EN + FR.
- `match(text)` — returns `{type:, verb:}` or nil.

`Common.parse_resolution` and `CGPM.flush_clause` both delegate to `Clauses.match`.

Open/closed: adding a verb = adding a row, not editing a switch.

## Acceptance
- One source of truth for "what verbs map to what types."
- Adding a new FR verb only touches `Clauses`.
- Existing parse output unchanged (verified by spec snapshots).

## Status
Complete.
