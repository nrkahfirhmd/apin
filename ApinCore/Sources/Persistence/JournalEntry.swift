// JournalEntry.swift
// ApinCore
//
// SwiftData model for a single journal entry: one asked question and its answer.
// See tasks/task-graph.md T6.
//
// `tags` (T11): manually entered/edited via `JournalEntryDetailView`, persisted through
// `JournalRepository.save(_:)`, and filterable via `JournalQuery.search(keyword:dateRange:tag:)`
// (see that type's `tagFilter` doc comment for why tag filtering is applied in memory rather
// than as part of the SwiftData `#Predicate`). Defaults to an empty array so pre-T11 entries
// remain valid.
//
// T18: dropped `@Attribute(.unique)` from `id` and added property-level default values to
// every stored property. Both are hard SwiftData+CloudKit requirements, not style choices:
// CloudKit mirroring (`ModelConfiguration(cloudKitDatabase: .automatic)`, wired up in
// `Apin/ApinApp.swift`) does not support unique constraints, and every attribute must be
// optional or carry a schema-level default so Core Data's CloudKit mirroring delegate can
// materialize incoming records without going through this type's custom `init` (init
// parameter defaults alone are not visible to the schema). No call site in this codebase
// relies on DB-level uniqueness enforcement for `id` (every `JournalEntry` is constructed
// with a fresh `UUID()`), so this is behaviorally a no-op outside of CloudKit sync.
//
// This file must never import SwiftUI/UIKit.

import Foundation
import SwiftData

// `Package.swift` only declares an iOS 26 platform minimum (this package ships to iOS/widget
// targets only); running `swift build`/`swift test` directly on macOS falls back to a very old
// default macOS deployment target where SwiftData isn't available, so the macOS 14 floor below
// is required purely to satisfy that host-tool build/test path.
@available(macOS 14, *)
@Model
public final class JournalEntry {
    public var id: UUID = UUID()
    public var question: String = ""
    public var answer: String = ""
    public var createdAt: Date = Date()
    /// User-entered tags (T11): edited via `JournalEntryDetailView`, defaults to empty.
    public var tags: [String] = []

    public init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        createdAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
        self.tags = tags
    }
}
