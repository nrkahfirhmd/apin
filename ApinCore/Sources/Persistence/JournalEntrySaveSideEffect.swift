// JournalEntrySaveSideEffect.swift
// ApinCore
//
// The seam later tasks hook into for "do something whenever a journal entry is saved,
// regardless of which flow (Ask, future import, etc.) created it." See tasks/task-graph.md
// T12 (portable export writer, the first conformer) and T14 (Spotlight indexing, the next
// one expected to land here).
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// A best-effort action run after a `JournalEntry` has been successfully persisted by
/// `SwiftDataJournalRepository`.
///
/// SwiftData is the source of truth for journal entries; conformances here represent
/// *mirrors*/conveniences built on top of it (a portable Markdown+JSON export, a Spotlight
/// search index, etc.) — never a second source of truth. Accordingly:
/// - Implementations must not throw. A failed side effect (e.g. a disk-full export write)
///   must never fail, roll back, or block the underlying SwiftData save; catch and
///   log/report your own errors internally instead of propagating them.
/// - Implementations should keep any actual I/O off the main actor where practical (see
///   `PortableExportWriter` for the pattern: snapshot the `Sendable` fields you need
///   synchronously, then hop off-actor for the real work).
///
/// ### Adding a new side effect (e.g. T14's Spotlight indexing)
/// Do **not** special-case a new hook inline inside `SwiftDataJournalRepository.save()`.
/// Instead:
/// 1. Add a new type conforming to `JournalEntrySaveSideEffect`.
/// 2. Append an instance of it to the `saveSideEffects` array passed into
///    `SwiftDataJournalRepository`'s initializer (see its default value for the pattern
///    `PortableExportWriter()` already uses).
///
/// `SwiftDataJournalRepository` runs every registered side effect, in array order, after
/// each successful save via its private `notifyDidSave(_:)` dispatcher.
@available(macOS 14, *)
public protocol JournalEntrySaveSideEffect: Sendable {
    /// Called after `entry` has been successfully persisted. Must not throw.
    ///
    /// Main-actor-isolated to match `JournalEntry`/`SwiftDataJournalRepository`'s own
    /// main-actor affinity (SwiftData models aren't `Sendable` and aren't safe to hand across
    /// actors) — conformances that need to do work off the main actor (e.g. file I/O) should
    /// synchronously copy the `Sendable` fields they need out of `entry` here, then hop off
    /// actor with that copy (see `PortableExportWriter` for the pattern).
    @MainActor
    func journalEntryDidSave(_ entry: JournalEntry) async
}
