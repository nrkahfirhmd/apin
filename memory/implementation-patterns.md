# Common Implementation Patterns

Reusable solutions that worked, so future tasks reuse them instead of reinventing them.
Different from coding-standards.md (rules) — this is "here's how we solved X before."

## Format

```markdown
### <pattern name>
- **Use when:** the situation this applies to
- **Approach:** the pattern, briefly, with a code pointer if useful (file:line or snippet)
- **Avoid when:** situations where this pattern doesn't fit
- **First used in:** sprint / task ID
```

---

<!-- Entries below this line -->

### Protocol seam around a system framework the test runner can't exercise live
- **Use when:** wrapping any Apple SDK type that is non-deterministic, requires live
  hardware/entitlements, or otherwise can't run in a headless test target (on-device model
  sessions, hardware availability checks, Core Spotlight indexing, etc.).
- **Approach:** define a narrow protocol capturing only the calls the app actually needs, write
  a real adapter conforming to it that talks to the live SDK type, and a fake/mock conformance
  for tests. Examples this cycle: `CapabilityGating` around `SystemLanguageModel`,
  `LanguageModelSessionProviding` around `LanguageModelSession`, `JournalSearchIndexing` around
  `CSSearchableIndex`. **Before writing the seam, verify the real SDK's actual API shape against
  its `.swiftinterface`** (or current Apple docs) rather than guessing — this project confirmed
  the `AppShortcutsProvider`/`@_alwaysEmitConformanceMetadata` constraint (see
  `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`) this way, not by
  assumption.
- **Avoid when:** the SDK type is already simple/deterministic enough to use directly and adding
  a protocol would just be indirection with no testability payoff.
- **First used in:** T2 (`CapabilityGating`), T4 (`LanguageModelSessionProviding`), T14
  (`JournalSearchIndexing`), Sprint 1.

### Save/delete-time side-effect array on a repository
- **Use when:** multiple independent, cross-cutting concerns need to react to a repository's
  write path (export mirroring, search indexing, future concerns like notifications) without
  each new concern requiring an edit to the repository's core CRUD logic.
- **Approach:** define a `Sendable`, non-throwing/best-effort protocol per event
  (`JournalEntrySaveSideEffect.journalEntryDidSave(_:)`,
  `JournalEntryDeleteSideEffect.journalEntryDidDelete(id:)`), hold an array of conformances on
  the repository (`saveSideEffects`, `deleteSideEffects`), and dispatch to all of them after the
  core write succeeds. New concerns are added by appending a conformance to the array, not by
  editing the repository's save/delete methods. Isolate each protocol's actor requirement to
  what it actually needs (e.g. delete only needs a `Sendable` `UUID`, so it doesn't need
  `@MainActor`; save needs the full non-`Sendable` model, so it does).
- **Avoid when:** the side effect must be able to fail the underlying write (this pattern is
  explicitly best-effort/non-throwing) — use a different mechanism if a side effect failing
  should roll back or block the save/delete itself.
- **First used in:** T12 (`JournalEntrySaveSideEffect`, export mirroring), T14
  (`JournalEntryDeleteSideEffect`, Spotlight deindexing), Sprint 1.

### Sendable snapshot types for crossing actor boundaries with @Model data
- **Use when:** data owned by a non-`Sendable` SwiftData `@Model` type needs to be passed across
  an actor boundary (e.g. from a `@MainActor`-isolated call site to a background task doing file
  I/O or indexing work).
- **Approach:** define a small, `Sendable`, value-type snapshot that copies out exactly the
  fields the receiving context needs (e.g. `JournalEntryExportSnapshot`,
  `JournalSearchIndexPayload`), construct it while still on the actor that owns the `@Model`
  instance, and pass the snapshot (not the model) across the boundary. Keeps Swift 6 strict
  concurrency checking clean without making the `@Model` type itself `Sendable` (which SwiftData
  models generally shouldn't be).
- **Avoid when:** the consuming code stays on the same actor as the `@Model` instance — no
  snapshot needed if there's no boundary to cross.
- **First used in:** T12 (`JournalEntryExportSnapshot`), T14 (`JournalSearchIndexPayload`),
  Sprint 1.
