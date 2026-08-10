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
  this protocol).
- **Status:** stable. `SwiftDataJournalRepository` is the sole conformance. Widget code
  (`ApinWidget/JournalWidgetStore.swift`) intentionally bypasses this protocol and reads
  SwiftData directly against the shared App Group container — it runs in a separate process and
  the protocol's `@MainActor`-isolated concrete type isn't reachable across that boundary; see
  `memory/adrs/002-shared-app-group-swiftdata-store-for-widget.md`.

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
- **Status:** stable. No live-device negative-path verification yet (see
  `memory/technical-debt.md` — the unsupported-device/OS path is structurally, not end-to-end,
  verified).
