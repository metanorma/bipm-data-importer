# 05 — Fix outcomes bugs

## Problem
- `lib/bipm/data/outcomes/meeting.rb:38-40` — `def url; document["metadata"]["source"]; end` returns the **source** field, not the URL. Copy/paste bug. The actual URL is at `document["metadata"]["url"]` and is currently unreachable.
- `meeting.rb:21-23` — `document` re-parses the YAML file from disk on every call.
- `resolution.rb:14-16` — `@meeting.document["resolutions"][index]` re-parses the parent meeting's YAML on every method call. Cascades: every `resolution.dates` triggers a `File.open` + `YAML.load`.
- `body.rb:5` — `Body#initialize(body, locale = nil)` accepts a `locale` argument that is silently discarded. Dead parameter.
- `localized_body.rb:4-7` — `LocalizedBody < Body` calls `super` (which sets `@body`, ignores `locale`) then sets `@locale` separately. The inheritance is being used as composition; Liskov is technically preserved but the constructor signature lies.

## Fix
- `Meeting#url` → `document["metadata"]["url"]`.
- Memoize `document` in `Meeting` and `Resolution` (`@document ||= ...` is fine — it's our own internal state, not another object's ivar, so the rule against `instance_variable_set/get` doesn't apply to ordinary `@ivar ||= ...`).
- Drop `locale` parameter from `Body#initialize`.
- Keep `LocalizedBody < Body` for now (it really is-a Body with an extra dimension); the dead param removal fixes the signature lie.

## Acceptance
- `Bipm::Data::Outcomes[:cipm][:en].meetings.first.url` returns the URL, not the source.
- Reading 100 resolutions does not open the YAML file 100 times.
- `Body.new(:cipm)` works without passing a locale.

## Status
Complete.
