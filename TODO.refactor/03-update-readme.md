# 03 — Update README

## Problem
`README.adoc:11-31` documents three executables that no longer exist:
- `bipm-fetch-cgpm`
- `bipm-fetch-cipm`
- `bipm-fetch-cipm-decisions`

Commit `c985489` (Consolidate CGPM scraping into the single bipm-fetch exe) collapsed them into `bipm-fetch`, but README was never updated. Users following README get `command not found`.

## Fix
Rewrite the Usage section to describe the single CLI:

```
bipm-fetch                                 # fetch all bodies, all languages
bipm-fetch --body=cgpm                     # one body
bipm-fetch --body=cgpm --language=fr       # one language
bipm-fetch --fork                          # parallel via fork
```

Also document the library API: `Bipm::Data::Importer.fetch(body_id).call`.

## Acceptance
- README matches `exe/` contents.
- Usage examples map onto real CLI flags.

## Status
Complete.
