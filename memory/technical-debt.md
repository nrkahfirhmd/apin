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
- **Status:** resolved (Cycle 2, T1). `SwiftDataJournalRepository.fetch(by:)`/`delete(id:)` no
  longer silently take `.first` on a multi-match — deliberate, documented multi-match handling
  plus a new `deduplicateEntries()` dedup pass (wired at a real call site) were added and covered
  by synthetic-duplicate unit tests in `ApinCoreTests` (`JournalRepositoryTests.swift`); verified
  correct by `/review`'s ground-truth pass (full diff read, 98/98 `ApinCoreTests` passing).

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
- **Status:** resolved (Cycle 2, T2). `INFOPLIST_KEY_UIBackgroundModes: [remote-notification]`
  was added to `project.yml`'s `Apin` target settings, but that setting alone turned out to be a
  **silent no-op**: `UIBackgroundModes` is not one of the ~95 keys Xcode's build system
  (`CoreBuildSystem.xcspec`, verified against this repo's Xcode 26 toolchain) auto-synthesizes
  from `INFOPLIST_KEY_*` settings into a `GENERATE_INFOPLIST_FILE: YES` target's `Info.plist` —
  confirmed empirically: a full clean build with only that setting produced an `Info.plist` with
  no `UIBackgroundModes` key at all. The actual fix also adds a new `Apin/Info.plist` base file
  (containing just `UIBackgroundModes: [remote-notification]`) plus `INFOPLIST_FILE:
  Apin/Info.plist` in `project.yml`'s `Apin` target settings, so `GENERATE_INFOPLIST_FILE: YES`
  merges that base file with the synthesized `INFOPLIST_KEY_*` content — the same pattern
  `ApinWidgetExtension` already used for its `NSExtension` key (another key outside the
  synthesis whitelist). Reconfirmed post-fix with a clean build + `plutil -p` on the built
  `Apin.app/Info.plist`, which now genuinely contains `UIBackgroundModes: [remote-notification]`.
  The dead `INFOPLIST_KEY_UIBackgroundModes` setting was kept in `project.yml` (documented as a
  no-op) purely for self-documentation/intent; it has no functional effect.

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
- **Status:** resolved (Cycle 2, T3). A `#if DEBUG`-gated override
  (`ApinCore/Sources/AI/CapabilityGateDebugOverride.swift`, reading the
  `APIN_DEBUG_CAPABILITY_OVERRIDE` launch-environment variable, wired through
  `AskViewModel.live`'s `resolvedCapabilityGate()`) was added, verified genuinely absent from a
  `-configuration Release` build via `nm`/`strings` (confirmed independently by `/review`), and
  used to actually render `AskView`'s real branch for all 5 `CapabilityGateResult` cases end to
  end in Simulator (iPhone 17, iOS 26.3) — each case's title/message/action-hint copy and icon
  were confirmed to match `CapabilityStatusCopyProvider`/`CapabilityUnavailableView` exactly, and
  no crash/fatalError was observed for any case. Full method, per-case observations, and the 5
  screenshots are persisted at `review/verification-assets/t3-capability-cases/` (`README.md` +
  `available.png`, `unsupportedDevice.png`, `unsupportedOS.png`, `appleIntelligenceDisabled.png`,
  `modelNotReady.png`) — this was previously missing (T3's first pass reported doing this in its
  chat summary but left no durable evidence, which `/review` correctly flagged as unverifiable;
  this rework actually performed and recorded it).

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

### App Group / iCloud container identifier drift: `com.kv.apin` (Swift source) vs. `com.apin.app` (`project.yml`)
- **Where:** `Apin/ApinApp.swift` (`appGroupIdentifier = "group.com.kv.apin"`, line 42, plus the
  `iCloud.com.kv.apin` reference in its doc comment, line 95) and
  `ApinWidget/JournalWidgetStore.swift` (`appGroupIdentifier = "group.com.kv.apin"`, line 45) —
  both hardcoded Swift literals — vs. `project.yml`'s `Apin`/`ApinWidgetExtension` target
  `entitlements.properties` (`group.com.apin.app`, `iCloud.com.apin.app`), which is what
  XcodeGen actually writes into `Apin/Apin.entitlements` and `ApinWidget/ApinWidget.entitlements`
  on every `xcodegen generate`.
- **What was skipped:** Not introduced by T2 — this drift already existed in the committed repo
  (both `project.yml` and the two Swift files were already at their current values at the
  commit T2 started from). It was masked because the checked-in, stale
  `Apin.entitlements`/`ApinWidget.entitlements` files still had the old `group.com.kv.apin` /
  `iCloud.com.kv.apin` values (self-consistent with the Swift literals, just inconsistent with
  `project.yml`), and nobody had re-run `xcodegen generate` since project.yml's App Group/iCloud
  container identifiers were last changed to `com.apin.app`, so the drift was never regenerated
  into the actual build artifacts. T2's required "regenerate the Xcode project" step
  (`xcodegen generate`, mandatory per its scope/acceptance criteria) regenerated the entitlements
  files to correctly match `project.yml`'s already-committed `com.apin.app` values — which
  exposed the mismatch against the Swift source's still-`com.kv.apin` literals.
- **Risk if unaddressed:** Confirmed via `xcodebuild test` on the `Apin` scheme: with entitlements
  now correctly matching `project.yml`, `Apin/ApinApp.swift`'s `makeModelConfiguration()`
  `fatalError`s at launch (`"App Group container 'group.com.kv.apin' is not reachable..."`)
  because that App Group no longer matches what's in the entitlement, so `ApinTests` cannot run
  (crashes before the test bundle loads) and the app cannot launch at all, on simulator or device.
  `ApinWidgetTests` still passes because `JournalWidgetStore.makeModelContainer()` degrades
  gracefully (`try?`) rather than trapping, but the widget would also silently show an empty
  timeline for the same reason. This is a **launch-blocking regression**, not cosmetic — the app
  cannot run in its current committed state (independent of anything CloudKit/push-related).
- **Effort to fix:** Small — update `group.com.kv.apin` → `group.com.apin.app` in both
  `Apin/ApinApp.swift` and `ApinWidget/JournalWidgetStore.swift` (kept in sync per their own doc
  comments), plus the `iCloud.com.kv.apin` reference in `ApinApp.swift`'s doc comment, plus
  checking `ApinTests`/`ApinWidgetTests` for any literal `com.kv.apin` assertions pinned against
  these constants (per `ApinApp.swift`'s doc comment referencing
  `ApinTests.ApinAppModelConfigurationTests`). Out of scope for T2 (Swift-source changes, not
  `project.yml`) — needs its own task.
- **Opened:** Cycle 2, discovered during T2 while verifying `xcodegen generate` + a full
  `xcodebuild test` run (not part of T2's stated acceptance criteria, but done as a
  self-verification step). Root cause predates T2 — likely an incomplete `com.kv.apin` →
  `com.apin.app` rename from an earlier cycle that updated `project.yml` and its generated
  entitlements but missed the two Swift-source literals.
- **Status:** resolved (Cycle 2, fixed directly during `/implement` orchestration after T2 flagged
  it, not by a dedicated task-runner task). Both Swift literals (`Apin/ApinApp.swift` line 42,
  `ApinWidget/JournalWidgetStore.swift` line 45) and the stray doc-comment reference
  (`ApinApp.swift` line 95, `iCloud.com.kv.apin` → `iCloud.com.apin.app`) updated to
  `group.com.apin.app`/`iCloud.com.apin.app`, matching `project.yml`'s entitlements. The two
  pinned regression tests (`ApinTests.ApinAppModelConfigurationTests`,
  `ApinWidgetTests.JournalWidgetStoreTests.test_appGroupIdentifier_matchesConfiguredEntitlement`)
  were updated to assert the corrected literal. Reconfirmed via `xcodebuild test` on the `Apin`
  scheme (`-only-testing:ApinTests -only-testing:ApinWidgetTests`): 26 `ApinTests` + 7
  `ApinWidgetTests`, all passing, no `fatalError` at launch.

### Stray git-tracked duplicate `Apin 2.xcodeproj` at repo root
- **Where:** repo root, `Apin 2.xcodeproj/` (5 tracked files: its own `project.pbxproj`,
  `.xcworkspace`, schemes including a duplicate-numbered `Apin 1.xcscheme`, and `xcuserdata`).
- **What was skipped:** An iCloud-Drive "conflicted copy" merge artifact (the same failure mode
  `memory/coding-standards.md`'s "iCloud Drive parallelism cap" lesson describes) produced a
  second, stray `.xcodeproj` bundle at repo root at some point before Sprint 1's base commit
  (`5038611`). It carries a stale `PRODUCT_BUNDLE_IDENTIFIER = com.kv.apin` (mixed with some
  `com.apin.app.*` values), inconsistent with `project.yml`'s real `com.apin.app`/
  `com.apin.app.*` values. Nobody has ever claimed cleaning it up as task scope, so it has never
  been removed.
- **Risk if unaddressed:** Confirmed harmless to *build correctness* today — nothing in
  `Apin.xcodeproj`, its schemes, `project.yml`, or any doc references "Apin 2," and every
  `xcodegen generate`/`xcodebuild` invocation across two full review/QA passes only ever touched
  the real `Apin.xcodeproj`. But it is dead weight with a stale, wrong bundle identifier that
  could confuse a future `open *.xcodeproj`/Spotlight double-click, and it will keep getting
  independently re-discovered and re-flagged every cycle (already flagged three times: T3, T11,
  and both Cycle-2 `/review` passes) until someone actually removes it.
- **Effort to fix:** Trivial — `git rm -r "Apin 2.xcodeproj"` in its own reviewable commit. Kept
  open rather than resolved because it's a destructive-looking git operation on a tracked
  directory nobody currently owns as task-scope; per this project's git-safety convention it
  should be confirmed with Kv (or done in an explicit, standalone commit) rather than silently
  removed as a side effect of any other task.
- **Opened:** predates Sprint 1 (present since the base commit `5038611`); first flagged as
  cleanup-worthy during Cycle 2 by T3's and T11's task-runners, then independently reconfirmed by
  both the original and follow-up `/review` passes and by `/qa`.
- **Status:** open. No task has claimed removing it. Recommend scheduling a trivial, dedicated
  cleanup task in a future cycle (e.g. cycle 3) with Kv's explicit go-ahead, so this stops being
  silently re-discovered every cycle without ever being resolved.
