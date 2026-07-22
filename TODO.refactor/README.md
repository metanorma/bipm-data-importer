# Refactor TODOs — bipm-data-importer 0.3.0 → next

All actionable items (01–16) are **complete**. Item 17 (typed domain models
via lutaml-model) is **deferred** — see its file for reasoning.

| # | Subject | Status |
|---|---------|--------|
| 01 | [Remove debug code](01-remove-debug-code.md) | Complete |
| 02 | [Fix gemspec](02-fix-gemspec.md) | Complete |
| 03 | [Update README](03-update-readme.md) | Complete |
| 04 | [Replace `require_relative` with autoload](04-replace-require-relative-with-autoload.md) | Complete |
| 05 | [Fix outcomes bugs](05-fix-outcomes-bugs.md) | Complete |
| 06 | [Unify clause taxonomy](06-unify-clause-taxonomy.md) | Complete |
| 07 | [Extract French parsing](07-extract-french-parsing.md) | Complete |
| 08 | [Extract data quirks registry](08-extract-data-quirks.md) | Complete |
| 09 | [Introduce Body registry](09-introduce-body-registry.md) | Complete |
| 10 | [Introduce Strategy pattern](10-introduce-strategy-pattern.md) | Complete |
| 11 | [Extract CLI class](11-extract-cli-class.md) | Complete |
| 12 | [Specs for Common](12-specs-common.md) | Complete |
| 13 | [Specs for CGPM/StaticIndex](13-specs-cgpm.md) | Complete |
| 14 | [Specs for AsciiMath](14-specs-asciimath.md) | Complete |
| 15 | [Specs for Outcomes domain](15-specs-outcomes.md) | Complete |
| 16 | [Quarantine failing unique_idents](16-quarantine-failing-specs.md) | Complete |
| 17 | [Typed domain models (lutaml-model)](17-typed-domain-models.md) | Deferred |

## Verification

- `bundle exec rspec`: 865 examples, **0 failures**, 9 pending (was 764/9/0)
- Suite runs in ~2s (was 1m 53s — memoization in Outcomes)
- `grep -rn "binding\.pry\|respond_to?\|instance_variable_set\|instance_variable_get\|\.send(:" lib exe spec` → empty
- `grep -rn "require_relative" lib exe spec bin` → empty
- `wc -l exe/bipm-fetch` → 4 (was 466)

## Library shape (final)

```
lib/bipm-data-importer.rb             # gem entry shim, 3 lines
lib/bipm/data/importer.rb             # namespace + autoloads + fetch/fetch_all
lib/bipm/data/importer/
  version.rb
  language.rb                         # first-class EN/FR value object
  body.rb                             # committee value object
  bodies.rb                           # open/closed registry
  quirks.rb                           # upstream-data patches
  clauses.rb                          # unified verb→type taxonomy (FR/EN symmetric)
  cli.rb                              # OptionParser-based CLI
  fetcher.rb                          # orchestrator: body → strategy → VCR mode
  cgpm.rb                             # backward-compat facade → Strategies::StaticIndex
  common.rb                           # SPA-scraping helpers (uses Clauses, Text::French)
  asciimath.rb                        # math-notation regex pipeline
  text.rb                             # parent namespace
  text/french.rb                      # month + date parsing
  strategies.rb                       # parent namespace
  strategies/base.rb                  # abstract strategy + recording_mode
  strategies/static_index.rb          # CGPM: static listing + per-resolution pages
  strategies/spa_meetings.rb          # everyone else: SPA meeting pages
lib/bipm/data/outcomes.rb             # read API namespace
lib/bipm/data/outcomes/
  body.rb localized_body.rb meeting.rb resolution.rb
  approval.rb action.rb consideration.rb
exe/bipm-fetch                        # 4 lines: require + CLI dispatch
```
