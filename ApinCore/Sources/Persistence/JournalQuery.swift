// JournalQuery.swift
// ApinCore
//
// Query-builder surface for `JournalRepository.fetch(matching:)`. Kept separate from
// `JournalEntry` so later tasks (T10 keyword/date-range search, T20 tag filtering) can add
// predicates/sort orders here without touching the model itself. Intentionally minimal this
// cycle — no predicate-construction helpers yet, just the container T10/T20 build on top of.
//
// This file must never import SwiftUI/UIKit.

import Foundation
import SwiftData

/// Describes how to filter and order a fetch against the journal store.
///
/// `JournalRepository.fetchAll()` is equivalent to `fetch(matching: .all)`. Future tasks that
/// need predicate-based filtering (keyword/date-range search, tag filters) construct a
/// `JournalQuery` with a `Predicate<JournalEntry>` rather than adding new repository methods
/// or new model fields.
@available(macOS 14, *)
public struct JournalQuery: Sendable {
    public var predicate: Predicate<JournalEntry>?
    public var sortBy: [SortDescriptor<JournalEntry>]

    public init(
        predicate: Predicate<JournalEntry>? = nil,
        sortBy: [SortDescriptor<JournalEntry>] = [SortDescriptor(\JournalEntry.createdAt, order: .reverse)]
    ) {
        self.predicate = predicate
        self.sortBy = sortBy
    }

    /// All entries, reverse-chronological (newest first).
    public static var all: JournalQuery { JournalQuery() }

    /// Builds a query for T10's keyword + date-range journal search.
    ///
    /// - `keyword`: matched case-insensitively against `question` OR `answer` via
    ///   `localizedStandardContains` (case- and diacritic-insensitive). An empty/whitespace-only
    ///   keyword is treated as "no keyword filter."
    /// - `dateRange`: inclusive bounds on `createdAt`. `nil` means "no date filter."
    ///
    /// Combining both narrows results (AND), matching T10's acceptance criteria — this is not
    /// a union/OR of the two filters.
    public static func search(keyword: String, dateRange: ClosedRange<Date>? = nil) -> JournalQuery {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate: Predicate<JournalEntry>?

        switch (trimmedKeyword.isEmpty, dateRange) {
        case (true, nil):
            predicate = nil

        case (true, .some(let range)):
            let lowerBound = range.lowerBound
            let upperBound = range.upperBound
            predicate = #Predicate<JournalEntry> { entry in
                entry.createdAt >= lowerBound && entry.createdAt <= upperBound
            }

        case (false, nil):
            predicate = #Predicate<JournalEntry> { entry in
                entry.question.localizedStandardContains(trimmedKeyword)
                    || entry.answer.localizedStandardContains(trimmedKeyword)
            }

        case (false, .some(let range)):
            let lowerBound = range.lowerBound
            let upperBound = range.upperBound
            predicate = #Predicate<JournalEntry> { entry in
                (entry.question.localizedStandardContains(trimmedKeyword)
                    || entry.answer.localizedStandardContains(trimmedKeyword))
                    && entry.createdAt >= lowerBound && entry.createdAt <= upperBound
            }
        }

        return JournalQuery(predicate: predicate)
    }
}
