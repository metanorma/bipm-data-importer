# 14 — Specs for AsciiMath

## Problem
`lib/bipm/data/importer/asciimath.rb` is 70 lines of regex pipeline with zero specs. Easy to break silently.

## Fix
Add `spec/bipm/data/importer/asciimath_spec.rb` with cases lifted from the existing YAML data:
- Greek letters: `"π"` → `"stem:[ pi ]"`, `"α"` → `"stem:[ alpha ]"`.
- Nucleus symbols: `"^14^C"` → nucleus stem.
- Units with powers: `"kg/m^2^"` → basic stem.
- Italic images: `image:: ital/m.gif[]` → `stem:[ m ]`.
- ± sign.
- Connectors between stems.
- ESC sequences round-trip correctly.

Pull ~10 representative strings from `data/cgpm/meetings-en/*.yml` as fixtures.

## Acceptance
- `bundle exec rspec spec/bipm/data/importer/asciimath_spec.rb` passes.
- Existing data-shape spec (`cgpm_spec.rb` stems checks) still passes.

## Status
Complete.
