// JournalRepository.swift
// ApinCore
//
// Persistence-layer entry point for `JournalEntry`. This protocol is the convergence point
// several later tasks hook into (T8 auto-save, T9/T10/T11 journal screens, T12 export writer,
// T14 Spotlight indexing, T18 CloudKit sync, T16/T17 widget, T11 tagging) — keep this shape
// stable. See tasks/task-graph.md T6.
//
// This file must never import SwiftUI/UIKit.

import Foundation
import SwiftData

/// CRUD + query surface over the journal store.
///
/// Isolated to the main actor: SwiftData `@Model` instances (like `JournalEntry`) are not
/// `Sendable` and aren't meant to cross isolation domains, so callers (app target, widget
/// extension, App Intents extension) `await` into this from their own context rather than the
/// repository hopping to a background actor and handing model instances back across the
/// boundary. This matches SwiftData's own `ModelContext`/`@Query` main-actor-affinity.
///
/// The macOS 14 floor below only matters for `swift build`/`swift test` run directly on a
/// macOS host (see `JournalEntry.swift`); the package's declared iOS 26 platform minimum
/// already exceeds it for real app/widget builds.
@available(macOS 14, *)
@MainActor
public protocol JournalRepository {
    /// Inserts a new entry (or persists changes to an existing one already in the store).
    func save(_ entry: JournalEntry) async throws

    /// All entries, reverse-chronological. Equivalent to `fetch(matching: .all)`.
    func fetchAll() async throws -> [JournalEntry]

    /// A single entry by its stable identifier, if it still exists.
    func fetch(by id: UUID) async throws -> JournalEntry?

    /// Entries matching an arbitrary predicate/sort order. Later tasks (T10 search, T11 tag
    /// filtering) build `JournalQuery` values against this rather than adding new methods.
    func fetch(matching query: JournalQuery) async throws -> [JournalEntry]

    /// Manual single-entry delete. No bulk/automatic deletion is in scope this cycle — see
    /// the retention policy note in tasks/task-graph.md T6.
    func delete(id: UUID) async throws
}

@available(macOS 14, *)
public extension JournalRepository {
    func fetchAll() async throws -> [JournalEntry] {
        try await fetch(matching: .all)
    }
}
