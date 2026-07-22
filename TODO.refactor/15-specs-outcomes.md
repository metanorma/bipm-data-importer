# 15 — Specs for Outcomes domain model

## Problem
`spec/bipm/data/outcomes_spec.rb` only checks `to_a.map(&:class)`. The actual API (`Meeting#url`, `Resolution#approvals`, etc.) has zero coverage. The `Meeting#url` bug survived because nothing tested it.

## Fix
Spec the real API against the existing `data/` directory:
- `Body.new(:cipm).file_path` ends with `/cipm/`.
- `Body#locales` returns `{fr:, en:}`.
- `LocalizedBody#meetings` is non-empty for cipm.
- `Meeting#title`, `#date`, `#source`, `#url` (this is the regression test for TODO 05), `#pdf`.
- `Meeting#resolutions` is a hash of `Resolution` instances.
- `Resolution#dates`, `#subject`, `#type`, `#id`, `#url`, `#reference`, `#reference_name`, `#reference_page`.
- `Resolution#approvals`, `#considerations`, `#actions` return hashes of typed objects.
- `Action#type` returns symbol, `Action#date_effective` returns Date.

No `double()`. Use `Bipm::Data::Outcomes[:cipm][:en].meetings.first` as the entry point.

## Acceptance
- `bundle exec rspec spec/bipm/data/outcomes_domain_spec.rb` passes.
- A future `Meeting#url` regression would be caught.

## Status
Complete.
