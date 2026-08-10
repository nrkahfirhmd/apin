// JournalSearchIndexing.swift
// ApinCore
//
// Protocol seam around CoreSpotlight's `CSSearchableIndex` so `JournalSearchIndexer` (T14)
// can be unit-tested with a fake conformance instead of a live on-device Spotlight index.
// `CoreSpotlightIndexAdapter` is the production conformance backed by the real framework.
// Mirrors the seam pattern `LanguageModelSessionProviding`/`FoundationModelsSessionAdapter`
// established for T4, and used the same way T2's `ModelHardwareAvailabilityProviding` wraps
// `SystemLanguageModel.availability` — a thin protocol around one system-framework surface,
// backed by a real adapter and a fake in tests. See tasks/task-graph.md T14.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// Minimal surface `JournalSearchIndexer` needs from a Spotlight index: add/update one
/// searchable item, or remove one by its unique identifier. Kept intentionally small so
/// fakes are trivial to write in tests.
///
/// Non-throwing to match `JournalEntrySaveSideEffect`/`JournalEntryDeleteSideEffect`'s
/// best-effort contract: a failed index/delete call must never fail, roll back, or block the
/// underlying SwiftData save/delete it's hooked into. Conformances are expected to catch and
/// log/report their own errors internally instead of propagating them.
public protocol JournalSearchIndexing: Sendable {
    /// Indexes (adds or updates) `payload` as one searchable item, keyed by `payload.id`.
    func index(_ payload: JournalSearchIndexPayload) async

    /// Removes the searchable item previously indexed for `id`, if any. A no-op (not an
    /// error) if nothing was indexed for `id`.
    func deleteIndexedItem(id: UUID) async
}
