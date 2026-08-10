// JournalSearchIndexer.swift
// ApinCore
//
// `JournalEntrySaveSideEffect`/`JournalEntryDeleteSideEffect` conformance that keeps every
// journal entry indexed as a Spotlight searchable item, so past entries surface as Spotlight
// search results (title/content mapped from question/answer) and disappear again once
// deleted (no orphaned search results). See tasks/task-graph.md T14.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// Bridges `SwiftDataJournalRepository`'s save/delete hooks to a `JournalSearchIndexing`
/// backend (by default, `CoreSpotlightIndexAdapter`, the real on-device Spotlight index).
///
/// Payload construction (`JournalSearchIndexPayload`) and the save/delete dispatch here are
/// exercised directly in tests against a fake `JournalSearchIndexing`, independent of
/// SwiftData/the main actor/a live Spotlight index.
@available(macOS 14, *)
public struct JournalSearchIndexer: JournalEntrySaveSideEffect, JournalEntryDeleteSideEffect {
    private let indexing: JournalSearchIndexing

    /// Primary initializer, written entirely against the `JournalSearchIndexing` seam.
    /// Inject a fake here in tests; production callers typically use the no-argument
    /// convenience initializer below instead.
    public init(indexing: JournalSearchIndexing) {
        self.indexing = indexing
    }

    #if canImport(CoreSpotlight)
    /// Convenience initializer backed by the real, on-device Spotlight index
    /// (`CoreSpotlightIndexAdapter`). This is the initializer
    /// `SwiftDataJournalRepository`'s default `saveSideEffects`/`deleteSideEffects` arrays use.
    public init() {
        self.init(indexing: CoreSpotlightIndexAdapter())
    }
    #endif

    // MARK: - JournalEntrySaveSideEffect

    @MainActor
    public func journalEntryDidSave(_ entry: JournalEntry) async {
        // Snapshot the `Sendable` fields we need while still on the caller's (main) actor —
        // `entry` itself is a SwiftData model and must not cross off-actor.
        let payload = JournalSearchIndexPayload(entry: entry)
        await indexing.index(payload)
    }

    // MARK: - JournalEntryDeleteSideEffect

    public func journalEntryDidDelete(id: UUID) async {
        await indexing.deleteIndexedItem(id: id)
    }
}
