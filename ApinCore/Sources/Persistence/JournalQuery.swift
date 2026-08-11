// JournalQuery.swift
// ApinCore
//
// Query-builder surface for `JournalRepository.fetch(matching:)`. Kept separate from
// `JournalEntry` so later tasks (T10 keyword/date-range search, T11 tag filtering) can add
// predicates/sort orders here without touching the model itself.
//
// This file must never import SwiftUI/UIKit.

import Foundation
import SwiftData

/// Describes how to filter and order a fetch against the journal store.
///
/// `JournalRepository.fetchAll()` is equivalent to `fetch(matching: .all)`. Future tasks that
/// need predicate-based filtering (keyword/date-range search) construct a `JournalQuery` with a
/// `Predicate<JournalEntry>` rather than adding new repository methods or new model fields.
@available(macOS 14, *)
public struct JournalQuery: Sendable {
    public var predicate: Predicate<JournalEntry>?
    public var sortBy: [SortDescriptor<JournalEntry>]

    /// T11's tag filter. **Deliberately not folded into `predicate`** — see this property's
    /// extended doc comment below for why, and `applyTagFilter(to:)` for how callers are
    /// expected to apply it.
    ///
    /// `nil`/empty means "no tag filter." When non-`nil`, only entries whose `tags` array
    /// contains this exact string (case-sensitive) match.
    ///
    /// Why this isn't a `#Predicate` clause like `keyword`/`dateRange`: SwiftData's `[String]`
    /// attribute (`JournalEntry.tags`) is stored by Core Data's SQLite store as a transformable
    /// attribute, not a to-many relationship. Core Data's SQL generator rejects any predicate
    /// that runs a subquery/`contains` test against a non-relationship collection attribute —
    /// confirmed directly against this exact model/attribute shape: `entry.tags.contains(_:)`
    /// inside `#Predicate` crashes the process (SIGSEGV) at fetch time, and the safer-looking
    /// `entry.tags.contains(where:)` form throws
    /// `NSInvalidArgumentException: "Can't have a non-relationship collection element in a
    /// subquery"` instead of crashing — neither is usable. This is a Core Data SQL-store
    /// limitation on the attribute's storage shape, not a bug specific to this project's
    /// toolchain, so it isn't expected to differ on a real device vs. this host-test
    /// environment. The tag filter is therefore applied in memory, after the SwiftData fetch
    /// (predicate + sort) runs, via `applyTagFilter(to:)` — both
    /// `SwiftDataJournalRepository.fetch(matching:)` and `JournalListView`'s `@Query`-backed
    /// live list call this the same way, so the two call sites can't drift.
    public var tagFilter: String?

    public init(
        predicate: Predicate<JournalEntry>? = nil,
        sortBy: [SortDescriptor<JournalEntry>] = [SortDescriptor(\JournalEntry.createdAt, order: .reverse)],
        tagFilter: String? = nil
    ) {
        self.predicate = predicate
        self.sortBy = sortBy
        self.tagFilter = tagFilter
    }

    /// All entries, reverse-chronological (newest first).
    public static var all: JournalQuery { JournalQuery() }

    /// Builds a query for T10's keyword + date-range journal search, extended by T11 with an
    /// optional exact-match tag filter.
    ///
    /// - `keyword`: matched case-insensitively against `question` OR `answer` via
    ///   `localizedStandardContains` (case- and diacritic-insensitive). An empty/whitespace-only
    ///   keyword is treated as "no keyword filter."
    /// - `dateRange`: inclusive bounds on `createdAt`. `nil` means "no date filter."
    /// - `tag`: exact (case-sensitive) match against any element of `entry.tags` — see
    ///   `tagFilter`'s doc comment for why this is applied in memory rather than folded into
    ///   `predicate`. An empty/whitespace-only or `nil` tag is treated as "no tag filter."
    ///
    /// All three filters combine with AND (not OR/union) when more than one is active, matching
    /// T10's and T11's acceptance criteria — `applyTagFilter(to:)` narrows further, it never
    /// widens, whatever `predicate` already matched.
    public static func search(
        keyword: String,
        dateRange: ClosedRange<Date>? = nil,
        tag: String? = nil
    ) -> JournalQuery {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTag = tag?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagFilter = (trimmedTag?.isEmpty ?? true) ? nil : trimmedTag

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

        return JournalQuery(predicate: predicate, tagFilter: tagFilter)
    }

    /// Applies `tagFilter` to an already-fetched/predicate-and-sort-filtered `entries` array, in
    /// order (a plain `filter`, so relative order — including whatever `sortBy` already
    /// produced — is preserved). A no-op passthrough when `tagFilter` is `nil`.
    ///
    /// See `tagFilter`'s doc comment for why this can't be expressed as part of `predicate`.
    public func applyTagFilter(to entries: [JournalEntry]) -> [JournalEntry] {
        guard let tagFilter else { return entries }
        return entries.filter { $0.tags.contains(tagFilter) }
    }
}
