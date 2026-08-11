// JournalDigest.swift
// ApinCore
//
// T12 — plain, testable computation of the weekly digest/streak view's two numbers: total
// questions-asked count and the current consecutive-day streak, both derived from
// `JournalEntry.createdAt`. Deliberately a free-standing value type + static function (not a
// view model, no SwiftUI import) so it's unit-testable without spinning up a SwiftData
// container or a view — the digest view (`Apin/Features/Digest/WeeklyDigestView.swift`) reads
// entries via `JournalRepository.fetchAll()`/`fetch(matching:)` and hands the array straight to
// `JournalDigest.compute(from:)`, mirroring `JournalDaySection`'s "pure grouping logic lives
// outside the view" pattern.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// Summary numbers for the weekly digest/streak view: how many questions have been asked in
/// total, and how many consecutive calendar days (counting back from the most recent entry)
/// have at least one entry.
@available(macOS 14, *)
public struct JournalDigest: Equatable, Sendable {
    /// Total number of journal entries (i.e. questions asked), all-time — not windowed to the
    /// last 7 days. `planning/spec.md`'s Req 11 ("weekly digest or streak view") and
    /// `tasks/task-graph.md`'s T12 acceptance criteria both only ask for "questions-asked count"
    /// with no explicit time window, so this counts every entry `compute(from:)` is given.
    public let questionCount: Int

    /// Consecutive-day streak, counting back from the most recent entry's calendar day. A day
    /// counts if at least one entry's `createdAt` falls on it; the streak stops at the first gap
    /// day with no entries. `0` when there are no entries at all.
    public let currentStreak: Int

    public init(questionCount: Int, currentStreak: Int) {
        self.questionCount = questionCount
        self.currentStreak = currentStreak
    }

    /// Computes both numbers from an unordered array of entries (any sort order is fine — this
    /// doesn't rely on `entries` already being sorted, unlike `JournalDaySection.grouped`).
    ///
    /// - Parameters:
    ///   - entries: Typically the result of `JournalRepository.fetchAll()`/`fetch(matching:)`.
    ///   - calendar: Injectable for deterministic tests; defaults to `.current`.
    ///   - now: Unused for the streak calculation itself (which anchors on the most recent
    ///     entry's day, not "today") but kept as a parameter for symmetry with
    ///     `JournalDaySection.grouped` and in case a future caller wants "today" available.
    public static func compute(
        from entries: [JournalEntry],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> JournalDigest {
        _ = now
        guard !entries.isEmpty else {
            return JournalDigest(questionCount: 0, currentStreak: 0)
        }

        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        guard let mostRecentDay = entryDays.max() else {
            return JournalDigest(questionCount: entries.count, currentStreak: 0)
        }

        var streak = 0
        var cursor = mostRecentDay
        while entryDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }

        return JournalDigest(questionCount: entries.count, currentStreak: streak)
    }
}
