# 002. Widget reads the journal via a dedicated `ModelContainer` pointed at a shared App Group store

Status: Accepted
Date: 2026-08-10
Sprint: Sprint 1 (see memory/sprint-summary.md)

## Context

The app target (`Apin`) and the widget extension (`ApinWidget`) are separate processes with
separate default (private, per-target) storage containers. WidgetKit extensions cannot read a
SwiftData `ModelContainer` constructed with the app target's default, unshared configuration —
by default each target's `ModelContainer(for: JournalEntry.self)` points at its own private
container, so the widget would only ever see an empty store even though the code compiles and
runs without error.

T16 (widget timeline/display) landed first and built the widget-side half of the fix: its own
`ModelContainer`/`ModelConfiguration` pointed at a shared App Group container
(`group.com.apin.app`) and store filename (`ApinJournal.sqlite`), with the App Group
entitlement added to both targets in `project.yml`. T16 explicitly did not touch
`Apin/ApinApp.swift`, which at that point still built its `ModelContainer` at the default,
per-target private location — leaving a known gap (documented in
`tasks/task-graph.md`'s "Blocked/notes" section) where the widget's App-Group-aware container
had nothing real to read, because the app was still writing to its own private, non-shared
store.

T18 (CloudKit sync) already needed to touch `ApinApp.swift`'s `ModelConfiguration` (to add
`cloudKitDatabase: .automatic`), so the App Group fix was folded into T18 rather than opened as
a separate task, since both concerns are "where does the SwiftData store physically live."

## Decision

Both `Apin/ApinApp.swift` and `ApinWidget/JournalWidgetStore.swift` construct their
`ModelConfiguration` against the exact same App Group container identifier
(`group.com.apin.app`) and store filename (`ApinJournal.sqlite`) — verified byte-for-byte
identical between the two targets, with `ApinAppModelConfigurationTests` and
`JournalWidgetStoreTests` independently pinning these literals as regression protection (the
two targets have no shared dependency/type to enforce this via the type system, so the tests
are the only thing preventing silent drift). `ApinApp`'s `modelContainer` is a single
static-let, built once, handed to both the SwiftUI environment (`.modelContainer(...)`) and
`ContentView` for repository construction — there is no second, competing container-
construction path in the app target. The widget extension builds its own separate
`ModelContainer` (WidgetKit extensions run in a separate process and cannot share the app's
in-memory container), but points it at the identical shared store location so it reads the
same on-disk data.

## Alternatives considered

- **Widget reads journal data via a different mechanism (e.g. app-writes-to-shared-file,
  widget-reads-file, or a Darwin notification + refetch)** — rejected: SwiftData + App Group
  container is the native, already-CloudKit-compatible mechanism and avoids hand-rolled
  cross-process sync code, consistent with the plan's general preference for SwiftData/CloudKit
  over custom sync.
- **Ship T16 and the App-Group app-side fix as fully separate tasks** — rejected during
  implementation once it became clear both changes touch the same file/concern
  (`ApinApp.swift`'s `ModelConfiguration`) and T18 needed to edit that file anyway; folding them
  together avoided two near-simultaneous edits to the same small file.

## Consequences

- Makes the widget's data genuinely live (reflects real app data), which was not true between
  T16 landing and T18 landing — any future cycle reading `tasks/task-graph.md` history should
  not assume T16 alone made the widget functional.
- Establishes a load-bearing fact for any future SwiftData+widget work in this codebase: **a
  widget extension needs its own `ModelContainer` explicitly pointed at the same shared App
  Group container/filename as the app — it cannot simply reuse the app's container**, because
  it runs in a separate process. Future widgets or extensions (e.g. a future Siri/Shortcuts
  extension needing direct data access) should follow this same pattern rather than
  rediscovering it.
- Creates a two-literal drift risk (`appGroupIdentifier`, `storeFileName` duplicated as string
  literals in two targets with no shared type) — currently mitigated only by
  `ApinAppModelConfigurationTests` / `JournalWidgetStoreTests` asserting parity, not by the
  type system. A future cycle could reduce this risk further by extracting the shared
  identifier/filename into a single constant consumable by both targets (e.g. via `ApinCore`),
  but this is not currently blocking anything and is not filed as debt since the tests catch
  drift today.
