# 12 — Specs for Common

## Problem
`lib/bipm/data/importer/common.rb` has zero specs. `Common.parse_resolution` is ~200 lines and contains the bulk of the non-CGPM parsing logic. No regression protection.

## Fix
Add `spec/bipm/data/importer/common_spec.rb` covering:
- `extract_date` — English, French, range, malformed.
- `format_message` — basic HTML→AsciiDoc.
- `replace_links` — CGPM/CIPM db URLs, relative hrefs, legacy `/jen/` typo.
- `replace_centers` — single center, group of centers.
- `ng_to_string` — encoding, nobr removal.
- `parse_resolution` — using a VCR cassette (e.g. `cassettes/cipm/cipm-recommendation-2018-1.yml`) for a recommendation, asserting structure: metadata, dates, subject, type, identifier, considerations, actions.

No `double()`. Real `Mechanize::Page` from cassette, or `Nokogiri::HTML(string)` for unit-level fixtures.

## Acceptance
- New spec file added.
- `bundle exec rspec spec/bipm/data/importer/common_spec.rb` passes.
- Pre-existing failures unchanged.

## Status
Complete.
