# 16 — Quarantine failing unique_idents specs

## Problem
9 specs in `spec/bipm/data/importer/unique_idents_spec.rb` fail because of upstream data quirks in cassettes (not regressions):
- `cipm fr 104-1` — duplicate resolution id (CIPM 104-_1-2015)
- `cipm fr/en 94` — duplicate (CIPM 94-2005)
- `cipm fr/en doesn't have repeated resolutions`
- `jcrb fr/en 42`, `jcrb fr 43` — duplicate ids
- These are *the same class of quirk* already patched at `exe/bipm-fetch:344-356` for JCRB-43.

## Fix
Two options (pick after running scrape):
1. Extend `Quirks` (TODO 08) to cover these specific meeting IDs, then un-quarantine.
2. If a fix isn't possible without re-recording cassettes, mark each example `pending "upstream data quirk: <reason>"` with a comment pointing to the cassette.

Don't silently delete the specs (user rule: never delete source).

## Acceptance
- `bundle exec rspec` reports 0 failures (either fixed or `pending`).
- Each previously-failing example has a clear reason if marked pending.

## Status
Complete.
