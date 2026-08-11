# API Reference

Internal and external APIs this project exposes or depends on. Updated by `memory-keeper`
whenever a task adds, changes, or deprecates an endpoint/interface.

## Format

```markdown
### <METHOD> <path or function signature>
- **Purpose:** one line
- **Auth:** how it's protected
- **Request / Params:** shape
- **Response:** shape
- **Added in:** sprint / task ID
- **Status:** stable | experimental | deprecated (replaced by X)
```

---

<!-- Entries below this line -->

### protocol JournalRepository
- **Purpose:** The single persistence seam for journal entries — every read/write path in the
  app (Ask/auto-save, Journal list/search/detail, export writer, Spotlight indexing) goes
  through this rather than touching SwiftData directly. Widget code is a documented, deliberate
  exception (see Status below).
- **Auth:** N/A (on-device, in-process; no auth layer).
- **Request / Params:** `save(_ entry: JournalEntry) async throws`,
  `fetchAll() async throws -> [JournalEntry]`,
  `fetch(by id: UUID) async throws -> JournalEntry?`,
  `fetch(matching query: JournalQuery) async throws -> [JournalEntry]` (predicate-based,
  supports keyword + date-range filtering, AND-combined),
  `delete(id: UUID) async throws`.
- **Response:** as above; all methods `async throws`.
- **Added in:** T6 (Sprint 1). Extended (not reshaped) by T12 (`saveSideEffects` hook), T14
  (`deleteSideEffects` hook), T18 (`ModelConfiguration`/CloudKit, lives in `ApinApp.swift`, not
  this protocol), T1 (Cycle 2 — `fetch(by:)`/`delete(id:)` multi-match handling: no longer an
  implicit `.first`, now deliberately documented/tested behavior for the case where multiple
  entries share an `id`; same signature, implementation-only change), T11 (Cycle 2 — `fetch(matching:)`
  now applies `JournalQuery.tagFilter`, when set, as an **in-memory, post-fetch** filter on top of
  the SwiftData `#Predicate` fetch — see the `JournalQuery` note below and
  `memory/adrs/003-in-memory-post-fetch-tag-filtering.md`; same signature, additive behavior).
- **Status:** stable. `SwiftDataJournalRepository` is the sole conformance. Widget code
  (`ApinWidget/JournalWidgetStore.swift`) intentionally bypasses this protocol and reads
  SwiftData directly against the shared App Group container — it runs in a separate process and
  the protocol's `@MainActor`-isolated concrete type isn't reachable across that boundary; see
  `memory/adrs/002-shared-app-group-swiftdata-store-for-widget.md`.

### struct JournalQuery
- **Purpose:** The predicate-building value type passed to `JournalRepository.fetch(matching:)`
  (and mirrored by `JournalListView`'s `@Query`-fetched-array filtering) — combines keyword,
  date-range, and (as of Cycle 2) tag conditions with AND semantics.
- **Auth:** N/A.
- **Request / Params:** `search(keyword: String?, dateRange: ClosedRange<Date>?, tag: String? =
  nil) -> JournalQuery` (the `tag` parameter is additive with a default, so every pre-existing
  two-argument call site still compiles unchanged); exposes `tagFilter: String?` and
  `applyTagFilter(to:) -> [JournalEntry]`.
- **Response:** keyword/date-range are compiled into a SwiftData `#Predicate` and pushed down into
  the fetch; `tagFilter`, when set, is **not** part of that `#Predicate` — it's applied afterward
  as a plain in-memory `Array` filter via `applyTagFilter(to:)`, called identically at both
  `SwiftDataJournalRepository.fetch(matching:)` and `JournalListView`'s computed `entries`
  property. This split exists because `JournalEntry.tags` (`[String]`) cannot be filtered inside a
  `#Predicate` at all — `.contains(_:)` segfaults the process, `.contains(where:)` throws
  `NSInvalidArgumentException` — a confirmed SwiftData/Core Data limitation, not a style choice.
  See `memory/adrs/003-in-memory-post-fetch-tag-filtering.md` and
  `memory/implementation-patterns.md`.
- **Added in:** T6 (Sprint 1, keyword/date-range). Extended by T11 (Cycle 2, `tag`/`tagFilter`).
- **Status:** stable.

### struct JournalDigest
- **Purpose:** Plain, testable value type computing the weekly-digest view's questions-asked count
  and consecutive-day streak from a set of `JournalEntry.createdAt` timestamps — deliberately kept
  out of the SwiftUI view per `memory/coding-standards.md`'s "extract non-trivial logic out of the
  view" convention.
- **Auth:** N/A.
- **Request / Params:** `JournalDigest.compute(from entries: [JournalEntry], calendar: Calendar =
  .current, now: Date = .now) -> JournalDigest`. Non-SwiftUI-importing, lives in
  `ApinCore/Sources/Persistence/JournalDigest.swift`.
- **Response:** a `JournalDigest` value exposing (at minimum) the questions-asked count and the
  current consecutive-day streak, computed purely from `createdAt` (does not read `tags`).
- **Added in:** T12 (Cycle 2). Consumed by `Apin/Features/Digest/WeeklyDigestView.swift`.
- **Status:** stable/new. Unit-tested (`JournalDigestTests.swift`) for no-entries, single-day,
  multi-day-consecutive, and broken/gap-streak cases.

### CapabilityGateDebugOverride / ForcedCapabilityGate (DEBUG-only)
- **Purpose:** A `#if DEBUG`-gated mechanism to force any `CapabilityGateResult` case at launch
  (via the `APIN_DEBUG_CAPABILITY_OVERRIDE` environment variable) so the unsupported-device/OS
  negative path (Req 7) can be manually rendered and verified in Simulator without needing
  genuinely disqualifying hardware. Sits *behind* `CapabilityGating`, not a change to that
  protocol's shape.
- **Auth:** N/A. Compiled out of Release builds entirely — confirmed absent from a
  `-configuration Release` binary via `nm`/`strings` (no `CapabilityGateDebugOverride`/
  `ForcedCapabilityGate`/`APIN_DEBUG_CAPABILITY_OVERRIDE` symbols or strings), independently
  re-verified by both `/review` and `/qa`.
- **Request / Params:** `ForcedCapabilityGate` conforms to `CapabilityGating`, constructed from
  `CapabilityGateDebugOverride`'s parsed environment-variable value;
  `AskViewModel.live(...)`'s `resolvedCapabilityGate()` checks the override first under `#if
  DEBUG` and falls back to `CapabilityGate.live()` unconditionally otherwise (and always, in
  Release).
- **Response:** the forced `CapabilityGateResult`, same shape `CapabilityGating` already returns.
- **Added in:** T3 (Cycle 2). `ApinCore/Sources/AI/CapabilityGateDebugOverride.swift`.
- **Status:** stable/new, DEBUG-only by design (not a tracked cross-cutting seam in the sense the
  other entries in this file are — listed here for discoverability given it's a new public type
  touching the capability-gate seam, not because it changes `CapabilityGating`'s contract).

### protocol AskAndSaveServicing / struct AskAndSaveService
- **Purpose:** The shared "capture question → run on-device model → save to journal" orchestration.
  Any future entry point that wants to produce and persist an answer (Spotlight, widget, a future
  inline App Intent) should call this rather than reimplementing the flow.
- **Auth:** N/A.
- **Request / Params:** takes a question string plus (indirectly, via constructor injection) an
  `AssistantSessionProviding`-conforming session and a `JournalRepository`; success path
  produces exactly one saved `JournalEntry`, failure path saves nothing.
- **Response:** the produced answer/`JournalEntry` on success, or a thrown/mapped error on
  failure (no partial saves).
- **Added in:** T8 (Sprint 1).
- **Status:** stable, but **located in the `Apin` app target, not `ApinCore`** — a deliberate
  deviation from the original plan wording, see
  `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`. T13/T17 currently reach
  this indirectly (deep-link → `AskView` → `AskViewModel.submit()` → this service) rather than
  calling it directly; a future inline-answer feature (T15-style) would need to relocate or
  otherwise expose this to `ApinCore` before an `AppIntent.perform()` could call it without
  going through the app UI.

### protocol JournalEntrySaveSideEffect / protocol JournalEntryDeleteSideEffect
- **Purpose:** The hook-pattern seam for composing independent, best-effort cross-cutting
  concerns onto `SwiftDataJournalRepository`'s save/delete path without editing the repository's
  core logic per new concern. Current conformances: portable Markdown/JSON export mirroring
  (`PortableExportWriter`, T12) and Spotlight search indexing (`JournalSearchIndexer`, T14).
- **Auth:** N/A.
- **Request / Params:** `JournalEntrySaveSideEffect.journalEntryDidSave(_ entry: JournalEntry)`
  (`@MainActor`-isolated — needs the full, non-`Sendable` `JournalEntry` model instance);
  `JournalEntryDeleteSideEffect.journalEntryDidDelete(id: UUID)` (not `@MainActor`-isolated —
  only needs the plain `Sendable` `UUID`, so pinning to the main actor is unnecessary). Both
  `Sendable` protocols with a documented non-throwing/best-effort contract (a failing side
  effect must not fail the underlying save/delete).
- **Response:** none (fire-and-forget, best-effort).
- **Added in:** T12 (save side effect), T14 (delete side effect), Sprint 1.
- **Status:** stable. Extension pattern is "append a conformance to
  `SwiftDataJournalRepository`'s `saveSideEffects`/`deleteSideEffects` array," not "special-case
  inline" — see `memory/implementation-patterns.md` for the reusable pattern writeup.

### protocol CapabilityGating
- **Purpose:** The single source of truth for on-device Apple Intelligence / `FoundationModels`
  availability. Every entry point (Ask screen, widget, App Intent) branches on this rather than
  re-deriving availability with its own `if #available`/hardware checks.
- **Auth:** N/A.
- **Request / Params:** exposes a typed result with (at minimum) `available`,
  `unsupportedDevice`, `unsupportedOS`, `appleIntelligenceDisabled` cases (plus
  `modelNotReady`, observed in test coverage — `FakeCapabilityGate`/`CapabilityGateResult`
  branches).
- **Response:** the typed `CapabilityGateResult`.
- **Added in:** T2 (Sprint 1). Consumed by T3 (unsupported UX), T7 (Ask screen),
  `CapabilityStatusCopyProvider` (copy per case).
- **Status:** stable. All 5 `CapabilityGateResult` cases have now been manually rendered
  end-to-end in Simulator (not just structurally unit-tested) via the `#if DEBUG`-only
  `CapabilityGateDebugOverride`/`ForcedCapabilityGate` override (T3, Cycle 2 — see the entry
  below); evidence at `review/verification-assets/t3-capability-cases/`. Still no verification on
  genuinely-ineligible *physical* hardware (Simulator-only), which is a narrower, separate gap
  from the one this entry used to describe.
