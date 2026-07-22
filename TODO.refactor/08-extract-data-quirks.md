# 08 — Extract DataQuirks registry

## Problem
Inline patches for upstream data mistakes, scattered through `exe/bipm-fetch` and `common.rb`:

- `exe/bipm-fetch:137` — `yr = nil if [bodyid, meeting_id] == [:CIPM, '104-2']`
- `exe/bipm-fetch:167` — `href = href.gsub('/106-2017/', '/104-_1-2015/') if href =~ %r"/ci/cipm/106-2017/resolution-[12]\z"`
- `exe/bipm-fetch:176-180` — CIPM/fr/94 duplicate-resolution rewrite
- `exe/bipm-fetch:189` — `href = href.gsub('/104-2015/', '/104-_1-2015/')`
- `exe/bipm-fetch:344-356` — JCRB/fr/43 numbering fix
- `lib/bipm/data/importer/common.rb:113-114` — `/jen/` → `/en/`, `/en/CGPM/jsp/` → `/en/CGPM/db/`

These are real, load-bearing patches. But they're open/closed violations: each new quirk requires editing the main scrape loop.

## Fix
- `lib/bipm/data/importer/quirks.rb` — registry of lambdas keyed by `(body, context)`.
- Each quirk is a small named function: `Quirks.for(:cipm, :fr, :meeting_94_duplicates)`.
- Main loop calls `Quirks.apply(context, value)` at well-defined hook points.

## Acceptance
- `grep -E "104-2|104-_1|106-2017|94-2005|JCRB.*43" exe/bipm-fetch lib/bipm/data/importer/strategies` → no inline conditionals, only registry lookups.
- Existing quirks still applied (verified by running CIPM/JCRB and diffing output).

## Status
Complete.
