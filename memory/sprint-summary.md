# Sprint Summaries

One entry per completed cycle through Planning → Implementation → Review → Knowledge.
Newest first.

## Format

```markdown
### Sprint <N> — YYYY-MM-DD to YYYY-MM-DD
- **Goal:** what this cycle set out to do (from engineering-plan.md)
- **Shipped:** tasks completed (link task IDs from tasks/task-graph.md)
- **Not shipped:** carried over, and why
- **QA verdict:** pass/fail, coverage delta, known bugs remaining
- **Notable decisions:** links to memory/decisions.md or memory/adrs/
```

---

<!-- Entries below this line, newest first -->

### Sprint 1 — 2026-08-10 (cycle 1, first cycle)
- **Goal:** Ship Apin v1 — an offline, on-device personality assistant (Apple Foundation
  Models) that answers questions with a consistent voice, auto-saves every Q&A pair to a
  searchable studying journal, and is reachable from iOS Spotlight and a home screen widget,
  per `planning/engineering-plan.md`.
- **Shipped:** T1–T14, T16–T19 (18/21 tasks) — all Must and Should backlog items: project
  scaffolding (T1), capability gate + unsupported-device UX (T2/T3), FoundationModels session
  wrapper (T4), personality system-instruction builder (T5), SwiftData journal model +
  repository (T6), Ask screen (T7), auto-save (T8), journal list/search/detail (T9/T10/T11),
  portable Markdown+JSON export (T12), Spotlight `AskApinIntent` deep link (T13), Spotlight
  indexing (T14), widget timeline + interactive quick-ask (T16/T17), CloudKit sync (T18),
  cross-screen empty/error/loading polish (T19).
- **Not shipped:** T15 (inline Siri/Spotlight answer spike, Should) — deliberately deferred,
  not started; deep-link-only (T13) remains the shipped baseline for Req 5, which is an
  acceptable outcome per the plan's own risk mitigation. T20 (tagging) and T21 (weekly
  digest/streak), both Nice-to-have — deliberately deferred, pull forward only if a future
  cycle has room to spare.
- **QA verdict:** Passed — 74 `ApinCoreTests` + 26 `ApinTests` + 7 `ApinWidgetTests` = 107
  tests, all green; `swiftlint lint` 0 violations across 78 files; clean rebuild from scratch;
  real simulator install + launch confirmed working (Ask screen renders correctly, no crash).
  Not yet release-ready: never run on a real device, no live iCloud/CloudKit sync test (no dev
  account available), live Spotlight/Siri discoverability never queried on-device (only
  build-time metadata verified). Two Definition-of-Done items remain explicitly open, not just
  flagged: "zero network requests when producing an answer" (static-analysis-only, no
  Instruments/network-conditioning capture) and the unsupported-device/OS negative path
  (structurally unit-tested only — `CapabilityStatusCopyProviderTests` — never rendered/driven
  end-to-end, and no debug override exists to force that state on a simulator that happens to
  report `.available`).
- **Notable decisions:** `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`
  (App Intents orchestration split across `ApinCore`/app target for real SDK reasons),
  `memory/adrs/002-shared-app-group-swiftdata-store-for-widget.md` (widget needs its own
  `ModelContainer` pointed at the shared App Group store); see `memory/decisions.md` for the
  lighter-weight open items (personality brief still a placeholder, answer-language mirroring
  implemented-but-Indonesian-support-unverified, retention policy implemented as assumed,
  T13's auto-submit-on-deep-link UX call needs Kv's confirmation). See
  `memory/technical-debt.md` for the four carried-forward debt items and
  `memory/lessons-learned.md` for the iCloud Drive parallelism incident and the `.gitignore`
  `*.md` defect.
