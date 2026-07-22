# 09 — Introduce Body registry

## Problem
- `exe/bipm-fetch:5-20` — bodies are an inline hash literal: `"JCRB" => 'https://...'`, 14 entries.
- `lib/bipm/data/importer/cgpm.rb:23-26` — `INDEX_URL` is a *separate* declaration of CGPM's URLs.
- Adding a 15th body requires editing the CLI script.
- The body id (`:CGPM` symbol vs `"cgpm"` string vs body name) is normalized ad-hoc: `bodyid.to_s.downcase.gsub(" ", "-").to_sym`.

## Fix
- `lib/bipm/data/importer/body.rb` — value object: `id`, `display_name`, `urls(locale)`, `strategy`.
- `lib/bipm/data/importer/bodies.rb` — frozen registry of all 14 bodies as `Body` instances.
- `Body.find(id)`, `Body.all`.
- `exe/bipm-fetch` and `CGPM` both source from `Bodies`.

Open/closed: adding a body = adding a `Body.new(...)` line to the registry, not editing the CLI.

## Acceptance
- One source of truth for "what bodies exist and where their pages are."
- `Bipm::Data::Importer::Bodies[:cgpm].strategy` → `:static_index`.
- `Bipm::Data::Importer::Bodies[:cipm].strategy` → `:spa_meetings`.

## Status
Complete.
