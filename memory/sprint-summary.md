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

### Sprint 4 — 2026-08-11 (cycle 4, language-scope closure + Spotlight invocation diagnosis)
- **Goal:** Ship the now-ungated English-only language-policy content swap (spec open question #5,
  sign-off already recorded in Cycle 4's planning session), re-run the build/metadata App Shortcut
  discoverability audit against the current toolchain, produce a new manual verification script
  isolating Siri-voice vs. Spotlight-typed invocation, and perform the routine iOS-version-floor
  spot-check — a deliberately small cycle, no new architecture, per `planning/engineering-plan.md`.
- **Shipped:** T1 (English-only `languagePolicy` content swap,
  `ApinCore/Sources/AI/PersonalityBrief.swift`, header doc comment updated — closes spec open
  question #5 in code, not just as a recorded decision), T2 (build/metadata App Shortcut audit
  re-run on Xcode 26.6 — clean pass, no defect, rules out a build-level cause for the Siri/Spotlight
  invocation gap and narrows the investigation to a runtime/device-state cause), T3 (new manual
  verification script `review/manual-verification/siri-spotlight-invocation-recheck.md`, isolating
  Siri-voice invocation from typed Spotlight search, re-checking the two named Settings toggles,
  cross-referencing T2's findings, blank Result section handed to Kv), T5 (routine iOS
  26+/A17-Pro-or-later re-check, fourth independent confirmation across four cycles, no
  discrepancy).
- **Not shipped:** T4 (record Kv's execution of T3's script) stays `blocked` — contingent on Kv
  running the script on the physical device and reporting back, which did not happen inside this
  cycle's session. Fourth consecutive cycle touching this class of device-verification blocker
  (Cycle 1: no hardware; Cycle 2: no device-driving tooling; Cycle 3: scripts existed, execution
  pending Kv's time; Cycle 4: a new script exists, execution still pending).
- **QA verdict:** Passed, ready for release. 131/131 tests (98 `ApinCore` + 26 `ApinTests` + 7
  `ApinWidgetTests`, unchanged — T1 is a content-only value swap covered dynamically by an existing
  test; T2/T3/T5 added no testable source), 0 regressions, 0 SwiftLint violations, clean
  `xcodebuild build`/`test` on the `Apin` scheme. The App Group/iCloud identifier drift bug class
  (which bit this project twice) was re-checked from source and confirmed absent. T2's
  build/metadata findings were independently reproduced by `/qa` with a fresh build, not just
  re-read from its report.
- **Notable decisions:** No new ADR this cycle (content/diagnostic/routine-check only, nothing
  rising to lasting architectural impact). See `memory/decisions.md` for four new entries this
  cycle: T1's implementation-closure entry, T2's clean-audit entry, T3's script-handoff entry, and
  T5's fourth re-confirmation entry. See `memory/technical-debt.md` for the new open entry
  (untracked/gitignored shadow `Apin 2.xcodeproj`/`Apin 3.xcodeproj` duplicates, distinct from the
  already-resolved *tracked*-duplicate entry). See `memory/implementation-patterns.md` for the
  newly-documented "Findings subsection in `tasks/task-graph.md`" pattern, now confirmed reusable
  across three cycles (Cycle 2's T9, Cycle 3's T5, this cycle's T2 and T5).

### Sprint 3 — 2026-08-11 (cycle 3, personality content + human-in-the-loop device verification)
- **Goal:** Ship the personality brief content swap (closing spec open question #2) and produce
  three precise manual verification scripts for Kv to execute on the physical iPhone 17 (zero-
  network, Indonesian fluency, Siri/Spotlight latency), plus a contingent follow-up to record
  results once Kv reports back — a deliberately small cycle, no new architecture, per
  `planning/engineering-plan.md`.
- **Shipped:** T1 (personality brief content swap — name framed as an "Apple Intelligence" pun,
  tone playful/cheerful, voice modeled on Crow Armbrust from *Trails of Cold Steel*: witty,
  charming, mercenary-rogue energy, quips over lectures, cocky but likable, still always answers
  directly), T2/T3/T4 (three self-contained manual verification scripts under
  `review/manual-verification/`, each with concrete pass/fail criteria and a blank Result section
  for Kv to fill in). Also closed, via Kv's confirmation in chat rather than code: the
  retention/archiving policy (spec open question #4, keep current keep-forever/manual-delete
  behavior) and T13's Spotlight/Siri auto-submit UX (spec open question #3 partial, keep current
  behavior) — both had been re-flagged as still-open every cycle since first shipped as
  assumptions. Also: the long-standing, git-tracked stray `Apin 2.xcodeproj` (flagged four times
  since Sprint 1) was confirmed with Kv and removed in a standalone commit (`1b8147f`) before this
  cycle's `/plan` ran.
- **Not shipped:** T5 (record Kv's device-verification results) — stays `blocked`; Kv has not yet
  executed T2/T3/T4's scripts on the physical iPhone 17 or reported results. Third consecutive
  cycle this class of item hasn't fully closed (cycle 1: no hardware; cycle 2: no device-driving
  tooling; cycle 3: scripts exist, execution now depends only on Kv's own time). See
  `memory/decisions.md`'s 2026-08-11 "device verification: scripts produced and handed off" entry.
- **QA verdict:** Passed, **ready for release — a first for this project** (prior two cycles'
  verdicts were explicitly "not release-ready" for different reasons each time). 131/131 tests
  passing (98 `ApinCoreTests` + 26 `ApinTests` + 7 `ApinWidgetTests`, same total as cycle 2's end
  state — T1 is content-only, T2–T4 are documentation, no new automated tests expected or added);
  `swiftlint lint --strict` 0 violations across 84 files; full clean builds (Debug simulator +
  `ApinCore`) succeed. This was a **two-pass `/qa` cycle**: the first pass found a release-blocking
  regression unrelated to T1–T4's own scope (see below), which was fixed and then independently
  re-verified from scratch by a second `/qa` pass before the "ready for release" verdict was given.
- **Notable decisions:** No new ADR this cycle (content/decisions/incident-response only, nothing
  rising to lasting-architectural-impact). See `memory/decisions.md` for the personality brief,
  retention policy, and T13 auto-submit resolutions, plus the device-verification handoff update.
  **Incident, not a planned decision:** at cycle start, the orchestrating session committed a
  pre-existing uncommitted working-tree diff (commit `042452c`) on the assumption — taken from
  `memory/technical-debt.md`'s "resolved (Cycle 2)" narrative for the App Group identifier drift —
  that it represented cycle 2's already-verified fix, without reading the diff first. The diff
  actually ran backwards, reintroducing the exact `group.com.kv.apin` launch-crash bug that had
  already been fixed once. Caught by the first `/qa` pass's independent test re-run, fixed by
  commit `b7c1536`, and re-verified from scratch by a second `/qa` pass (131/131 tests). See
  `memory/lessons-learned.md`'s 2026-08-11 Sprint 3 entry (new failure mode, distinct from the
  Sprint 1 iCloud-Drive-parallelism entry) and the new standing rule in
  `memory/coding-standards.md` ("never commit a pre-existing uncommitted diff without reading it
  first"). `memory/technical-debt.md`'s App Group entry carries a Cycle-3 addendum noting the
  regression-and-refix (status remains resolved, not reopened).

### Sprint 2 — 2026-08-11 (cycle 2, hardening + open-decision closure)
- **Goal:** Close the four release-readiness gaps carried in `memory/technical-debt.md`, resolve
  or re-confirm the four open product/UX decisions in `memory/decisions.md` plus spec open
  question #1, and pick up the cycle-1 deferred Nice-to-have backlog (tagging, weekly digest) if
  room allowed — a deliberate hardening/completion cycle, no new architecture, per
  `planning/engineering-plan.md`.
- **Shipped:** T1 (`JournalEntry.id` multi-match handling + `deduplicateEntries()` dedup pass),
  T2 (`UIBackgroundModes: [remote-notification]`, plus discovering the `INFOPLIST_KEY_*`
  synthesis-whitelist gap that required an `Info.plist` base file), T3 (`#if DEBUG`-gated
  capability-gate override + manual Simulator verification of all 5 `CapabilityGateResult`
  cases, evidence at `review/verification-assets/t3-capability-cases/`), T6/T7/T8 (personality
  brief, retention policy, T13 auto-submit UX — all re-checked, all still genuinely unresolved by
  Kv, correctly re-flagged rather than silently re-assumed), T9 (iOS 26+/A17 Pro-or-M-series
  minimum re-verified against live Apple docs, no discrepancy), T11 (tag entry/edit UI + in-memory
  tag search filter — first UI consumer of `JournalEntry.tags`), T12 (weekly digest/streak view,
  `JournalDigest.compute(from:calendar:now:)`). Also fixed outside task scope, directly by the
  orchestrating session: the App Group/iCloud container identifier drift
  (`group.com.kv.apin` → `group.com.apin.app` in two Swift-source literals), a real
  launch-blocking regression exposed by T2's mandatory `xcodegen generate` step — see
  `memory/lessons-learned.md`.
- **Not shipped:** T4 (dynamic zero-network-requests verification), T5 (Indonesian fluency
  verification on real hardware), T10 (inline Siri/Spotlight latency spike) — all three remain
  `pending`, deliberately deferred to cycle 3. Not a hardware-availability gap this time: Kv
  confirmed a physical iPhone 17 and active Apple Developer account are available in principle,
  and the device was even observed `connected` via `devicectl` partway through the cycle. The
  actual blocker is a **tooling gap**: the orchestrating CLI session has no way to interactively
  drive a physical device's UI (Instruments capture, typing real Indonesian questions, timing a
  live response all need real interaction; available tooling is Simulator-only). Kv was asked and
  explicitly chose to defer T4/T5/T10 to cycle 3 rather than hand-drive the device this session or
  accept a CLI-only best-effort proxy — see `memory/decisions.md`'s 2026-08-11 entry.
- **QA verdict:** Passed — 131 tests total (98 `ApinCoreTests` + 26 `ApinTests` + 7
  `ApinWidgetTests`, up from 107 in cycle 1, +24 net new), all green; `swiftlint lint --strict` 0
  violations across 84 files; 0 regressions found; clean rebuild from scratch (Debug and
  Release); Release build independently confirmed via `nm`/`strings` to have T3's debug override
  genuinely compiled out, and via `PlistBuddy` to have T2's `UIBackgroundModes` fix genuinely
  present in the built `Info.plist`; fresh Simulator install + launch confirmed clean (including a
  real end-to-end regression check that the App Group identifier fix actually resolved the
  launch-time `fatalError`). Not yet externally release-ready — same honesty framing as cycle 1:
  every check this cycle, including the App Group fix and T3's capability-gate verification, was
  exercised only on Simulator, never on Kv's actual iPhone 17; live CloudKit cross-device sync and
  live Spotlight/Siri discoverability remain unexercised on-device; T4/T5/T10 (the three tasks
  that would exercise real hardware) remain pending. `/review` required one short rework loop
  (T1/T3/T11 sent back for missed `memory/`-file acceptance criteria and, for T3, missing
  verification evidence) before reaching a clean `/qa` pass — see `review/review-report.md`'s
  addendum.
- **Notable decisions:** New ADR-003 (in-memory, post-fetch tag filtering — SwiftData `#Predicate`
  cannot filter `JournalEntry.tags`, a real, load-bearing constraint on how `JournalQuery` can
  ever filter that field, not just an implementation detail). See `memory/decisions.md` for the
  lighter-weight items: T4/T5/T10's tooling-gap blocker (new this cycle), T6/T7/T8 re-flagged
  still-open, T9's re-verification with no discrepancy found. See `memory/technical-debt.md` for
  three debt items resolved this cycle (T1's dedup guard, T2's background mode, T3's manual
  verification) plus the App Group identifier drift (resolved, found+fixed outside task scope) and
  the new open item (stray `Apin 2.xcodeproj`, flagged repeatedly, still unaddressed). See
  `memory/lessons-learned.md` for the identifier-drift root-cause writeup.

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
