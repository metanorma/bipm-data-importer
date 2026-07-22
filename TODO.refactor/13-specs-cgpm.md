# 13 — Specs for CGPM

## Problem
`lib/bipm/data/importer/cgpm.rb` has zero behavioral specs. The `cgpm_spec.rb` that exists only checks data-shape invariants on already-written YAML.

## Fix
Add unit specs for pure functions:
- `CGPM.normalize_verb("considering.")` → `"considering"`
- `CGPM.normalize_verb("et noting")` → `"noting"`
- `CGPM.parse_date_text("15 février 2018")` → `"2018-02-15"`
- `CGPM.parse_date_text("15 février – 16 février 2018")` → last day of range
- `CGPM.extract_resolution_urls(html, "en")` — sample listing HTML, assert extracted URLs
- `CGPM.parse_resolution(page, "en")` — use a VCR cassette (`cassettes/cgpm/cgpm-resolution-1-1.yml`) and assert structure.
- `CGPM.flush_clause(...)` — input/output assertions on verb/message/lists.

No `double()`.

## Acceptance
- `bundle exec rspec spec/bipm/data/importer/cgpm_parser_spec.rb` passes.

## Status
Complete.
