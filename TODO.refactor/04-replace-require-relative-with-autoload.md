# 04 — Replace `require_relative` with autoload

## Problem
User rule: "NEVER use `require_relative` for internal library code. Never use `require` with a path to code within your own library. Use Ruby `autoload` instead. Define autoload entries in the **immediate parent namespace's file** — create that file if it doesn't exist."

Current violations:
- `lib/bipm-data-importer.rb:3` — `require_relative "bipm/data/importer"`
- `lib/bipm/data/importer.rb:3-6` — `require_relative "importer/asciimath"`, `common`, `cgpm`, `version`
- `lib/bipm/data/importer/common.rb:7` — `require_relative "asciimath"`
- `lib/bipm/data/outcomes.rb:1-3` — `require_relative "outcomes/body"`, `localized_body`, `meeting`
- `exe/bipm-fetch:3` — `require_relative '../lib/bipm-data-importer'`
- `spec/spec_helper.rb:3-4` — `require_relative "../lib/bipm/data/importer"`, `outcomes`
- `spec/bipm/data/importer/cgpm_spec.rb:1` — `require_relative "../../../spec_helper"`
- `spec/bipm/data/importer/unique_idents_spec.rb:1` — same

Also note: `lib/bipm/data/outcomes.rb:34-40` already declares `autoload :Body, ...` etc. — but these are **dead** because lines 1-3 `require_relative` the files eagerly.

## Fix
- `lib/bipm-data-importer.rb` → `require "bipm/data/importer"` (top-level entry; this is the only `require` allowed because it's the gem entry-point load).
- `lib/bipm/data/importer.rb` → drop all `require_relative`; declare `autoload :CGPM, "bipm/data/importer/cgpm"`, etc.
- `lib/bipm/data/importer/common.rb` → drop `require_relative "asciimath"`; the parent already autoloads it.
- `lib/bipm/data/outcomes.rb` → drop the three `require_relative`; keep the existing autoloads.
- `exe/bipm-fetch` → `require "bipm-data-importer"` (depends on bundler to add `lib/` to `$LOAD_PATH`; gemspec installs it via `require_paths = ["lib"]`).
- `spec/spec_helper.rb` → `require "bipm/data/importer"` + `require "bipm/data/outcomes"` (via `$LOAD_PATH`).
- `spec/bipm/data/importer/*_spec.rb` → `require "spec_helper"` (RSpec adds spec dir to LOAD_PATH via `--require`).

## Acceptance
- `grep -rn "require_relative" lib exe spec` → empty.
- `grep -rn "^require ['\"]bipm" lib exe` → only the gem entry-point shim.
- `bundle exec rspec` still passes (modulo the pre-existing 9 failures).
- `bundle exec bipm-fetch --body=cgpm` still runs.

## Status
Complete.
