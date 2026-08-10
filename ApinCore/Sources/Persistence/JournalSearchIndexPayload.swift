// JournalSearchIndexPayload.swift
// ApinCore
//
// A `Sendable` copy of the fields of a `JournalEntry` needed to build a Spotlight
// searchable item (T14). Kept as a plain value type (rather than passing the SwiftData
// `@Model` class across an actor boundary) so the actual CoreSpotlight indexing call can
// safely run off the main actor — mirrors the pattern `JournalEntryExportSnapshot`
// established for T12, kept as its own type since indexing's payload shape (no
// `schemaVersion`/`tags` needed here) is unrelated to the portable export format.
// See tasks/task-graph.md T14.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// The fields needed to index (or re-index) one journal entry as a Spotlight searchable
/// item: `id` as the stable identifier, `question` maps to the item's title, `answer` maps
/// to its content description, and `createdAt` becomes the item's content creation date.
public struct JournalSearchIndexPayload: Equatable, Sendable {
    public var id: UUID
    public var question: String
    public var answer: String
    public var createdAt: Date

    public init(id: UUID, question: String, answer: String, createdAt: Date) {
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
    }

    /// Snapshots the fields of `entry` needed for indexing. Read synchronously (no `await`)
    /// so callers can take this snapshot before handing the (now-`Sendable`) result off to
    /// background indexing work — per `JournalEntrySaveSideEffect`'s contract, callers should
    /// only call this while `entry` is known-safe to touch (i.e. before it's handed off
    /// across actors elsewhere).
    @available(macOS 14, *)
    public init(entry: JournalEntry) {
        self.init(id: entry.id, question: entry.question, answer: entry.answer, createdAt: entry.createdAt)
    }
}
