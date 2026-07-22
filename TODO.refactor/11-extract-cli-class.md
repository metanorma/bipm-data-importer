# 11 — Extract CLI class

## Problem
`exe/bipm-fetch` is 466 lines of: argv parsing (`--fork`, `--body=`), body iteration, language iteration, scraping dispatch, fork management. Multiple responsibilities.

After TODO 10 (strategies), most of the scraping moves to library classes. What remains in `exe/` should be a thin shim that delegates to `Bipm::Data::Importer::CLI`.

## Fix
- `lib/bipm/data/importer/cli.rb` — class with `parse(argv)` → options struct, `run`.
- Uses `OptionParser` instead of string matching on `ARGV[0]`.
- `exe/bipm-fetch` becomes ~5 lines: `require "bipm-data-importer"; exit Bipm::Data::Importer::CLI.new(ARGV).run`.

## Acceptance
- `exe/bipm-fetch` < 10 lines.
- CLI flags: `--body=ID`, `--language=LANG`, `--fork`, `--help`.
- `--help` prints usage.
- Unknown flag → error + usage.

## Status
Complete.
