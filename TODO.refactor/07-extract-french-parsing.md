# 07 — Extract French parsing

## Problem
- `lib/bipm/data/importer/common.rb:410-431` — `extract_date` does French month translation + date parsing, with `binding.pry` in the rescue path.
- `lib/bipm/data/importer/cgpm.rb:145-164` — `parse_date_text` does the same translation (different month list, slightly different regex), no pry.
- `cgpm.rb:139-143` — `normalize_verb` strips French/English leading conjunctions.

Two implementations of "BIPM French date string → ISO8601." They drift (cgpm has more months; common has `octobre` missing).

## Fix
- New `lib/bipm/data/importer/text/french.rb` module: `MONTHS` (fr → en), `parse_date(str)`, `translate_months(str)`.
- `Common.extract_date` and `CGPM.parse_date_text` both delegate.
- Drop the `binding.pry` paths (covered by TODO 01).

## Acceptance
- One French month table.
- `Common.extract_date('15 février 2018')` == `CGPM.parse_date_text('15 février 2018')` == `Date.iso8601('2018-02-15')`.
- All existing month translations preserved.

## Status
Complete.
