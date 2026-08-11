// SwiftDataJournalRepository.swift
// ApinCore
//
// SwiftData-backed `JournalRepository`. See tasks/task-graph.md T6.
//
// This file must never import SwiftUI/UIKit.

import Foundation
import SwiftData

/// Default `JournalRepository` implementation, backed by a `ModelContext`.
///
/// Construct with `ModelContainer(for: JournalEntry.self)` for on-disk storage, or with an
/// in-memory `ModelConfiguration`'s container (see `ApinCoreTests`) for tests/previews. A
/// dedicated `ModelContext(modelContainer)` is created rather than using
/// `ModelContainer.mainContext`, so this type owns its context explicitly instead of relying
/// on SwiftData's shared main-actor singleton.
@available(macOS 14, *)
@MainActor
public final class SwiftDataJournalRepository: JournalRepository {
    private let modelContext: ModelContext

    /// Ordered list of best-effort actions run after every successful save. This is the
    /// seam for T12 (portable export) and T14 (Spotlight indexing) — see
    /// `JournalEntrySaveSideEffect`'s doc comment for the "how to add a new one" contract.
    /// Injectable (default `[PortableExportWriter(), JournalSearchIndexer()]`) so tests can
    /// substitute fakes/spies or an empty array.
    private let saveSideEffects: [JournalEntrySaveSideEffect]

    /// Ordered list of best-effort actions run after every successful delete. This is the
    /// seam for T14 (removing a deleted entry's Spotlight index item) — see
    /// `JournalEntryDeleteSideEffect`'s doc comment for why this is a separate array from
    /// `saveSideEffects` and the "how to add a new one" contract. Injectable (default
    /// `[JournalSearchIndexer()]`) so tests can substitute fakes/spies or an empty array.
    private let deleteSideEffects: [JournalEntryDeleteSideEffect]

    public init(
        modelContext: ModelContext,
        saveSideEffects: [JournalEntrySaveSideEffect] = [PortableExportWriter(), JournalSearchIndexer()],
        deleteSideEffects: [JournalEntryDeleteSideEffect] = [JournalSearchIndexer()]
    ) {
        self.modelContext = modelContext
        self.saveSideEffects = saveSideEffects
        self.deleteSideEffects = deleteSideEffects
    }

    public convenience init(
        modelContainer: ModelContainer,
        saveSideEffects: [JournalEntrySaveSideEffect] = [PortableExportWriter(), JournalSearchIndexer()],
        deleteSideEffects: [JournalEntryDeleteSideEffect] = [JournalSearchIndexer()]
    ) {
        self.init(
            modelContext: ModelContext(modelContainer),
            saveSideEffects: saveSideEffects,
            deleteSideEffects: deleteSideEffects
        )
    }

    public func save(_ entry: JournalEntry) async throws {
        // `insert` is a no-op for an entry already tracked by this context, so this
        // covers both "create" (new entry) and "persist in-place edits to an existing,
        // already-fetched entry" without needing to branch on prior attachment state.
        modelContext.insert(entry)
        try modelContext.save()
        await notifyDidSave(entry)
    }

    /// Runs every registered `saveSideEffect` for `entry`, in order. Side effects are
    /// contractually non-throwing/best-effort (see `JournalEntrySaveSideEffect`), so this
    /// never fails or rolls back the save that already succeeded above. This is the single
    /// place a save-time hook (e.g. T12's export mirror, T14's Spotlight indexing) needs to
    /// be reachable from — add your conformance to the `saveSideEffects` array passed into
    /// this repository's initializer, not a new call site here.
    private func notifyDidSave(_ entry: JournalEntry) async {
        for sideEffect in saveSideEffects {
            await sideEffect.journalEntryDidSave(entry)
        }
    }

    /// Returns the "canonical" entry for `id`.
    ///
    /// `id` is only an application-level unique key, not a DB-enforced one — SwiftData's
    /// CloudKit mirroring does not support unique constraints on `@Model` properties, so
    /// `@Attribute(.unique)` was deliberately removed from `JournalEntry.id` in T18 (see
    /// `memory/database-schema.md`). No current code path constructs a duplicate `id`, but a
    /// future CloudKit merge/import edge case could. If the store ever contains more than one
    /// entry sharing `id`, this deliberately returns the one with the most recent `createdAt`
    /// (newest write "wins," mirroring the last-writer-wins semantics CloudKit's own
    /// field-level conflict resolution already uses — see `ApinApp.swift`'s
    /// `makeModelConfiguration()` doc comment) instead of an arbitrary, order-dependent
    /// `.first`. Older duplicates are left in the store until `deduplicateEntries()` runs; this
    /// method never deletes anything itself.
    public func fetch(by id: UUID) throws -> JournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Fetches entries matching `query.predicate`/`query.sortBy`, then narrows further by
    /// `query.tagFilter` (T11) in memory — see `JournalQuery.tagFilter`'s doc comment for why
    /// the tag filter can't be folded into `predicate` itself (a real Core Data SQL-store
    /// limitation on `JournalEntry.tags`' storage shape, confirmed directly, not an assumption).
    public func fetch(matching query: JournalQuery) throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: query.predicate,
            sortBy: query.sortBy
        )
        let results = try modelContext.fetch(descriptor)
        return query.applyTagFilter(to: results)
    }

    /// Deletes every entry matching `id`.
    ///
    /// In the normal, non-duplicate case this deletes exactly the one entry `fetch(by:)` would
    /// have returned. If duplicates exist for `id` (see `fetch(by:)`'s doc comment), a single
    /// "delete this entry" request removes *all* of them, not just the most recent one —
    /// leaving a hidden duplicate behind after a delete that looked fully successful would be
    /// a worse outcome than removing extra rows that should never have existed. Still a no-op,
    /// as before, when `id` doesn't match anything.
    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.id == id })
        let matches = try modelContext.fetch(descriptor)
        guard !matches.isEmpty else { return }

        for entry in matches {
            modelContext.delete(entry)
        }
        try modelContext.save()
        await notifyDidDelete(id: id)
    }

    /// Defensive cleanup pass: removes duplicate `JournalEntry` rows that share an `id`,
    /// keeping exactly one survivor per `id` (the same "most recent `createdAt` wins" rule as
    /// `fetch(by:)`).
    ///
    /// `id` has been an application-level-only unique key since T18 (see `fetch(by:)`'s doc
    /// comment and `memory/technical-debt.md`, "No DB-level uniqueness guarantee on
    /// `JournalEntry.id` post-CloudKit"). This pass exists for duplicates that could only have
    /// been created *before* T1's `fetch(by:)`/`delete(id:)` fix landed (e.g. a hypothetical
    /// prior CloudKit merge/import edge case) — no code path in this repository produces a new
    /// duplicate going forward. Safe to call repeatedly (a no-op once no duplicates remain) and
    /// intended to run once per app launch; see `Apin/ApinApp.swift` for the wired call site.
    ///
    /// Deliberately bypasses `deleteSideEffects`: the surviving entry for each `id` keeps that
    /// same `id`, so running the delete-side-effect path (which deindexes by `id`, see
    /// `JournalEntryDeleteSideEffect`) would incorrectly remove the Spotlight index entry for
    /// the entry that's staying, not just the duplicates being discarded.
    @discardableResult
    public func deduplicateEntries() throws -> Int {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allEntries = try modelContext.fetch(descriptor)

        var seenIDs = Set<UUID>()
        var removedCount = 0
        for entry in allEntries {
            if seenIDs.contains(entry.id) {
                modelContext.delete(entry)
                removedCount += 1
            } else {
                seenIDs.insert(entry.id)
            }
        }

        if removedCount > 0 {
            try modelContext.save()
        }
        return removedCount
    }

    /// Runs every registered `deleteSideEffect` for `id`, in order. Side effects are
    /// contractually non-throwing/best-effort (see `JournalEntryDeleteSideEffect`), so this
    /// never fails or rolls back the delete that already succeeded above. This is the single
    /// place a delete-time hook (e.g. T14's Spotlight index removal) needs to be reachable
    /// from — add your conformance to the `deleteSideEffects` array passed into this
    /// repository's initializer, not a new call site here.
    private func notifyDidDelete(id: UUID) async {
        for sideEffect in deleteSideEffects {
            await sideEffect.journalEntryDidDelete(id: id)
        }
    }
}
