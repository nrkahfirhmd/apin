# Unresolved Technical Debt

Known shortcuts and their cost. Checked by the `planner` subagent before every new
`/plan` so debt gets scheduled, not forgotten.

## Format

```markdown
### <short title>
- **Where:** file/module/system
- **What was skipped:** the shortcut taken and why (deadline, unknown scope, etc.)
- **Risk if unaddressed:** what breaks or gets worse over time
- **Effort to fix:** rough size
- **Opened:** sprint / task ID
- **Status:** open | scheduled (sprint N) | resolved (sprint N, task ID)
```

---

<!-- Entries below this line -->

### No DB-level uniqueness guarantee on JournalEntry.id post-CloudKit
- **Where:** `ApinCore/Sources/Persistence/JournalEntry.swift`
  (`SwiftDataJournalRepository.fetch(by:)`/`delete(id:)`)
- **What was skipped:** T18 removed `@Attribute(.unique)` from `JournalEntry.id` because
  SwiftData's CloudKit mirroring does not support unique constraints on `@Model` properties —
  this was a forced trade-off, not a shortcut for convenience.
- **Risk if unaddressed:** No current code path constructs a `JournalEntry` with anything other
  than a fresh `UUID()`, so no duplicate exists today. But if a future feature (e.g. an
  import/restore flow, or a CloudKit conflict/merge edge case) ever produces two entries sharing
  an `id`, `fetch(by:)`/`delete(id:)` (both call `.first` on a predicate match) would silently
  operate on only one of them, potentially leaving an orphaned duplicate after what looks like a
  successful delete.
- **Effort to fix:** Small-to-medium — would need either an app-level uniqueness check on
  insert/import paths, or a periodic dedup pass; no fix currently exists.
- **Opened:** Sprint 1, T18 (flagged by reviewer in `review/review-report.md`).
- **Status:** open.

### Missing UIBackgroundModes: [remote-notification]
- **Where:** `project.yml` (`Apin` target settings) / generated `Info.plist`
  (`GENERATE_INFOPLIST_FILE: YES`, no hand-maintained `Info.plist` to edit separately).
- **What was skipped:** T18 wired CloudKit sync (`ModelConfiguration(cloudKitDatabase:
  .automatic)`) but did not add the `remote-notification` background mode, so background
  push-triggered CloudKit sync cannot fire. Foreground sync is unaffected.
- **Risk if unaddressed:** Journal entries created on another device won't sync to a
  backgrounded/terminated instance of the app until it's next foregrounded — degrades, but does
  not break, requirement 9 (Should-priority iCloud sync).
- **Effort to fix:** Small — one-line addition,
  `INFOPLIST_KEY_UIBackgroundModes: [remote-notification]` (or equivalent) in `project.yml`'s
  `Apin` target settings.
- **Opened:** Sprint 1, T18 (flagged by reviewer, independently reconfirmed by `/qa` via a
  runtime CloudKit diagnostic: `"CloudKit push notifications require the 'remote-notification'
  background mode in your info plist"`, logged during both the review and QA test runs).
- **Status:** open.

### "Zero network requests when producing an answer" not dynamically verified
- **Where:** `ApinCore/Sources/AI/AssistantSessionService.swift` (and the wrapper's concrete
  session adapter), `Apin/Features/Ask/AskView.swift` / `AskViewModel.swift` — the actual
  model-invocation path.
- **What was skipped:** This Definition-of-Done item (flagged in `planning/engineering-plan.md`
  as "safety-critical to the product's value proposition") has never had a dynamic
  Instruments/network-conditioning verification pass, in any environment across the whole
  cycle — no such tooling was available headless. Only a static-analysis argument exists:
  `grep -rln "URLSession\|CFNetwork\|import Network"` across `Apin/`, `ApinCore/`, `ApinWidget/`
  returns zero matches; the model-invocation path imports only `Foundation` and
  `FoundationModels`.
- **Risk if unaddressed:** Static analysis is reassuring but not equivalent to a live traffic
  capture — a future dependency addition, or unexpected behavior inside an Apple framework,
  would not be caught by grep alone. Since this is explicitly called out as safety-critical to
  the product's core value proposition (fully offline), shipping externally without ever having
  dynamically verified it is a real gap, not a formality.
- **Effort to fix:** Small once a real device + Instruments/Network Link Conditioner access
  exists — this is a verification task, not a code change (assuming the static-analysis result
  holds).
- **Opened:** Sprint 1 (gap present since T4/T7); explicitly logged as debt starting this
  `/remember` pass per reviewer's and QA's recommendation (previously undocumented anywhere
  durable).
- **Status:** open.

### Unsupported-device/OS path only structurally verified, never manually exercised
- **Where:** `Apin/Features/Ask/CapabilityUnavailableView.swift` /
  `CapabilityUnavailableCopy.swift` (T3), consumed by `AskView`'s
  `if viewModel.capability == .available { ... } else { CapabilityUnavailableView(...) }` branch.
- **What was skipped:** All 5 `CapabilityGateResult` cases are covered only by
  `CapabilityStatusCopyProviderTests` (copy-string-level unit tests) and
  `AskViewModelTests` (view-model state reflects a fake gate's result) — no test or manual pass
  has ever rendered `CapabilityUnavailableView` through an actual SwiftUI render pass or driven
  `AskView`'s real branch end-to-end. QA confirmed there is no debug override/environment-variable
  hook anywhere in the app to force a non-`.available` capability state at runtime
  (`ProcessInfo`/`debugOverride`/`forceCapability` grep across `Apin/` and `ApinCore/Sources/`
  returns nothing), and QA's own launch smoke test happened to land on `.available` on the test
  Mac/simulator combination, so it didn't exercise the unsupported path either.
- **Risk if unaddressed:** This is a Must-have requirement's *negative* path (requirement 7:
  "graceful, clear handling on devices/OS versions that don't support" the on-device model) —
  shipping without ever having rendered it leaves open the possibility of a crash or silent
  no-op specifically on the hardware/OS combination where it matters most, which unit tests of
  copy strings cannot catch.
- **Effort to fix:** Medium — either add a debug-only override switch to force each
  `CapabilityGateResult` case for manual verification, or obtain a genuinely-ineligible
  simulator/device (e.g. an iOS 26 simulator on an Intel Mac) and write a manual test plan entry.
- **Opened:** Sprint 1, T3/T19 (flagged as a "genuine gap, not just a flagged limitation" by
  `/qa`).
- **Status:** open.

### (Resolved during cycle, not open debt — historical record) `.gitignore` bare `*.md` defect
- **Where:** repo-root `.gitignore`, line 1, introduced by T1's scaffolding.
- **What was skipped:** T1's scaffolding added a bare `*.md` ignore rule, which matched every
  Markdown file in the repository — including `README.md`, `CLAUDE.md`, and everything under
  `planning/`, `tasks/`, `memory/`, `review/`. No task's acceptance criteria named
  `.gitignore`'s content, so it went uncaught by every individual task self-report.
- **Risk if unaddressed:** Would have silently prevented this entire project's `memory/`-driven
  workflow from ever being committed to git — a repo-wide defeat of the project's own knowledge
  loop.
- **Effort to fix:** Trivial (remove one line) — already done.
- **Opened:** Sprint 1, T1. **Resolved:** Sprint 1, found and fixed during `/review`'s
  ground-truth verification pass (not credited to any specific task); independently reconfirmed
  fixed by `/qa` via `git check-ignore -v`.
- **Status:** resolved (Sprint 1, `/review`).
