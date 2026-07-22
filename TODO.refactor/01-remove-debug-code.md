# 01 — Remove debug code

## Problem
- `lib/bipm/data/importer/common.rb:253` — commented `#binding.pry if ps.count != 1`.
- `lib/bipm/data/importer/common.rb:426` — `binding.pry if date <= Date.parse("0000-01-01")`. Drops the production scraper into a pry REPL on any malformed date.
- `lib/bipm/data/importer/common.rb:430` — bare `binding.pry` inside `rescue Date::Error`. Same problem.
- `exe/bipm-fetch:240` — `pp [:duplicates_found, decisions]`. Spams stdout during normal runs.

## Fix
Delete the debug primitives. If the date-parse failure path needs visibility, raise a typed error (`Bipm::Data::Importer::DateParseError`) and let the caller log/continue.

## Acceptance
- `grep -rn "binding.pry\|binding.remote_pry" lib exe` → empty.
- `grep -rn "pp \[" lib exe` → empty.
- Scraper does not hang waiting for REPL input on bad input.

## Status
Complete.
