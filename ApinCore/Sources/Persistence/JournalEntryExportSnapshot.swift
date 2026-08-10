// JournalEntryExportSnapshot.swift
// ApinCore
//
// A `Sendable`, `Codable` copy of the fields of a `JournalEntry` needed to write the
// portable Markdown/JSON export (T12). Kept as a plain value type (rather than passing the
// SwiftData `@Model` class across an actor boundary) so the actual file I/O can safely run
// off the main actor. See tasks/task-graph.md T12.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// The on-disk JSON shape written by `PortableExportWriter`, and the source data for the
/// paired Markdown file.
///
/// `schemaVersion` is a deliberate hedge: no consumer of this export exists yet (a future Mac
/// companion app is out of scope this cycle), so the format is kept intentionally simple, and
/// `schemaVersion` lets a future consumer detect/handle format changes without requiring a
/// breaking migration of already-written files.
public struct JournalEntryExportSnapshot: Codable, Equatable, Sendable {
    /// Bump this whenever the JSON/Markdown shape changes in a way a consumer needs to know
    /// about.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var question: String
    public var answer: String
    public var createdAt: Date
    public var tags: [String]

    public init(
        schemaVersion: Int = JournalEntryExportSnapshot.currentSchemaVersion,
        id: UUID,
        question: String,
        answer: String,
        createdAt: Date,
        tags: [String]
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
        self.tags = tags
    }

    /// Snapshots the fields of `entry` needed for export. Read synchronously (no `await`)
    /// so callers can take this snapshot before handing the (now-`Sendable`) result off to
    /// background file I/O. `JournalEntry`'s own stored properties are plain, non-isolated
    /// value types, so this doesn't require actor isolation itself — but per
    /// `JournalEntrySaveSideEffect`'s contract, callers should still only call this while
    /// `entry` is known-safe to touch (i.e. before it's handed off across actors elsewhere).
    @available(macOS 14, *)
    public init(entry: JournalEntry) {
        self.init(
            id: entry.id,
            question: entry.question,
            answer: entry.answer,
            createdAt: entry.createdAt,
            tags: entry.tags
        )
    }
}
