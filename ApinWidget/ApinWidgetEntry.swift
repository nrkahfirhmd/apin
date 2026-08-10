// ApinWidgetEntry.swift
// ApinWidget
//
// Timeline entry for the recent-entry widget (T16). `hasEntry` distinguishes the real
// "most recent question" state from the empty state (`.empty`) that
// `ApinWidgetEntryView` renders when there's no journal data yet or the shared store
// isn't reachable -- see `JournalWidgetStore`.

import ApinCore
import WidgetKit

struct ApinWidgetEntry: TimelineEntry {
    let date: Date
    let question: String
    let answerSnippet: String
    let createdAt: Date?
    let hasEntry: Bool

    static let empty = ApinWidgetEntry(
        date: Date(),
        question: "",
        answerSnippet: "",
        createdAt: nil,
        hasEntry: false
    )

    /// Used for the widget gallery preview and `getSnapshot(in:)` when `context.isPreview`.
    static let placeholder = ApinWidgetEntry(
        date: Date(),
        question: "What's the capital of Indonesia?",
        answerSnippet: "Jakarta is Indonesia's capital and largest city...",
        createdAt: Date(),
        hasEntry: true
    )

    /// Maps a fetched `JournalEntry` (or `nil` -- no entries yet, or the shared store was
    /// unreachable) to what the timeline renders. Pure/deterministic and independent of
    /// `ModelContainer`/`ModelContext`, so it's unit-testable without a live SwiftData
    /// store -- see `ApinWidgetProvider.fetchLatestEntry()`, the only production caller.
    static func make(from journalEntry: JournalEntry?, answerSnippetLength: Int = 140) -> ApinWidgetEntry {
        guard let journalEntry else { return .empty }

        return ApinWidgetEntry(
            date: Date(),
            question: journalEntry.question,
            answerSnippet: String(journalEntry.answer.prefix(answerSnippetLength)),
            createdAt: journalEntry.createdAt,
            hasEntry: true
        )
    }
}
