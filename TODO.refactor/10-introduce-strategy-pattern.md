# 10 — Introduce Strategy pattern

## Problem
`exe/bipm-fetch:32-53` dispatches CGPM via string comparison and a global VCR/WebMock shutdown:

```ruby
if bodyid == :CGPM
  VCR.eject_cassette
  VCR.turn_off!(ignore_cassettes: true)
  WebMock.disable!
  Bipm::Data::Importer::CGPM.run(a, BASE_DIR)
  next
end
# ... otherwise, 350 lines of inline SPA scraping ...
```

Adding a new "special" body means another `if bodyid == :XYZ` branch. The VCR/WebMock side effects are global and triggered by string match.

## Fix
- `lib/bipm/data/importer/strategies/base.rb` — abstract `call(agent, body, base_dir, languages:)`.
- `lib/bipm/data/importer/strategies/static_index.rb` — what CGPM does (extracted from cgpm.rb).
- `lib/bipm/data/importer/strategies/spa_meetings.rb` — what the other 13 bodies do (extracted from `exe/bipm-fetch:55-459`).
- Each strategy declares its own `recording_mode` (cassette name vs `:live`). The Fetcher queries the strategy before each request.
- `Bipm::Data::Importer.fetch(body_id)` returns a `Fetcher` that picks the strategy from `Bodies[body_id].strategy`.

Open/closed: new strategy = new class + register in `Bodies`.

## Acceptance
- `exe/bipm-fetch` has no `if bodyid == :CGPM`.
- `exe/bipm-fetch` has no references to `VCR` or `WebMock`.
- Both strategies are reachable via `Bipm::Data::Importer.fetch(:cgpm)` and `Bipm::Data::Importer.fetch(:cipm)`.

## Status
Complete.
