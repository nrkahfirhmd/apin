// JournalEntryDeleteSideEffect.swift
// ApinCore
//
// New seam (T14), the delete-side counterpart to `JournalEntrySaveSideEffect`: "do
// something whenever a journal entry is deleted, regardless of which flow triggered the
// delete." See tasks/task-graph.md T14.
//
// Why this is a *new* seam rather than reusing `saveSideEffects`: before T14, no task needed
// a delete-time hook — T12's portable export is export-only (mirrors on save; no requirement
// to prune the mirrored `.md`/`.json` files on delete), so `SwiftDataJournalRepository`'s
// `delete(id:)` had no equivalent array to begin with. T14 introduces `deleteSideEffects`
// specifically because leaving a stale Spotlight item behind after a manual delete would
// violate this task's "no orphaned search results" acceptance criterion. It's kept as its
// own protocol/array (mirroring `JournalEntrySaveSideEffect`/`saveSideEffects` 1:1) rather
// than overloading the save-effect array with an enum/"was this a save or delete" branch,
// since that would blur the single-purpose, non-throwing/best-effort contract
// `JournalEntrySaveSideEffect`'s doc comment establishes for saves specifically.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// A best-effort action run after a `JournalEntry` has been successfully deleted by
/// `SwiftDataJournalRepository`. See `JournalEntrySaveSideEffect` for the save-side sibling
/// of this seam and the contract both share:
/// - Implementations must not throw. A failed side effect (e.g. a Spotlight delete call that
///   errors) must never fail, roll back, or block the underlying SwiftData delete; catch and
///   log/report your own errors internally instead of propagating them.
/// - Implementations should keep any actual I/O off the main actor where practical.
///
/// Unlike `JournalEntrySaveSideEffect`, this is not `@MainActor`-isolated: only the deleted
/// entry's plain, `Sendable` `id` is available (and needed) at delete time, not the SwiftData
/// model instance itself, so there's no non-`Sendable` state to protect by pinning this to
/// the main actor.
///
/// ### Adding a new delete-time side effect
/// Add a new type conforming to `JournalEntryDeleteSideEffect` and append an instance of it
/// to the `deleteSideEffects` array passed into `SwiftDataJournalRepository`'s initializer
/// (see its default value, `[JournalSearchIndexer()]`, for the pattern).
public protocol JournalEntryDeleteSideEffect: Sendable {
    /// Called after the entry identified by `id` has been successfully deleted. Must not
    /// throw.
    func journalEntryDidDelete(id: UUID) async
}
