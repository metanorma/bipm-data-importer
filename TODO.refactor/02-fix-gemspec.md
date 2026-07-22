# 02 — Fix gemspec

## Problem
- `bipm-data-importer.gemspec:38` — `pry` is a **runtime** dependency. Debugger; should be dev.
- `bipm-data-importer.gemspec:14` — `required_ruby_version = ">= 2.5.0"`. 2.5 EOL 2021. User wants `>= 3.3.0`.
- `bipm-data-importer.gemspec:24` — file-exclusion regex still mentions `appveyor`/`travis`/`circleci` paths that no longer exist (cleanup commit `5ca19cf`).
- `.rubocop.yml` — `TargetRubyVersion: 2.5`. Must match gemspec.

## Fix
- Move `pry` to `add_development_dependency`.
- Set `required_ruby_version = ">= 3.3.0"`.
- Set `TargetRubyVersion: 3.3` in `.rubocop.yml`.
- Drop the `(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor` branch — keep only what's still relevant.

## Acceptance
- `bundle exec rubocop` reports no TargetRubyVersion mismatches.
- `bundle install` still resolves.
- `gem build` succeeds.

## Status
Complete.
