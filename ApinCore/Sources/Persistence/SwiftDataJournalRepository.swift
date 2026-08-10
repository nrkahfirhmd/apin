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

    public func fetch(by id: UUID) throws -> JournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    public func fetch(matching query: JournalQuery) throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: query.predicate,
            sortBy: query.sortBy
        )
        return try modelContext.fetch(descriptor)
    }

    public func delete(id: UUID) async throws {
        guard let entry = try fetch(by: id) else { return }
        modelContext.delete(entry)
        try modelContext.save()
        await notifyDidDelete(id: id)
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
