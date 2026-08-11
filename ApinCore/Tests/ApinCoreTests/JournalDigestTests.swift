// JournalDigestTests.swift
// ApinCoreTests
//
// Unit tests for T12's `JournalDigest.compute(from:)`. Uses a fixed `Calendar`/day-offset
// helper (not `JournalRepository`/SwiftData) since this is pure computation over an array of
// `JournalEntry` instances — no persistence needed. Covers the acceptance criteria's four
// required cases: no entries, single-day entries, multi-day consecutive streak, broken streak
// (gap day).

import XCTest
@testable import ApinCore

@available(macOS 14, *)
final class JournalDigestTests: XCTestCase {
    /// Fixed reference calendar/day so tests are deterministic regardless of host time zone.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// `2026-08-11 12:00:00 UTC`, used as "day 0" — entries are built as offsets from this.
    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 11, hour: 12))!
    }

    /// Builds an entry whose `createdAt` is `dayOffset` calendar days before `referenceDate`
    /// (0 = same day as the reference date), at a fixed time of day.
    private func entry(daysAgo dayOffset: Int, question: String = "Q") -> JournalEntry {
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: referenceDate)!
        return JournalEntry(question: question, answer: "A", createdAt: date)
    }

    // MARK: - No entries

    func testComputeWithNoEntriesReturnsZeroCountAndZeroStreak() {
        let digest = JournalDigest.compute(from: [], calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 0)
        XCTAssertEqual(digest.currentStreak, 0)
    }

    // MARK: - Single-day entries

    func testComputeWithMultipleEntriesOnSameDayCountsAllAndStreakIsOne() {
        let entries = [
            entry(daysAgo: 0, question: "Q1"),
            entry(daysAgo: 0, question: "Q2"),
            entry(daysAgo: 0, question: "Q3")
        ]

        let digest = JournalDigest.compute(from: entries, calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 3)
        XCTAssertEqual(digest.currentStreak, 1)
    }

    // MARK: - Multi-day consecutive streak

    func testComputeWithConsecutiveDaysProducesMatchingStreak() {
        let entries = [
            entry(daysAgo: 0),
            entry(daysAgo: 1),
            entry(daysAgo: 2),
            entry(daysAgo: 3)
        ]

        let digest = JournalDigest.compute(from: entries, calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 4)
        XCTAssertEqual(digest.currentStreak, 4)
    }

    func testComputeConsecutiveStreakIsUnaffectedByEntryOrder() {
        // Deliberately shuffled/unsorted input — `compute(from:)` must not assume sorted input.
        let entries = [
            entry(daysAgo: 2),
            entry(daysAgo: 0),
            entry(daysAgo: 1)
        ]

        let digest = JournalDigest.compute(from: entries, calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 3)
        XCTAssertEqual(digest.currentStreak, 3)
    }

    // MARK: - Broken streak (gap day)

    func testComputeWithGapDayStopsStreakAtTheGap() {
        // Entries on "today" and 1 day ago, then a gap (no entry 2 days ago), then an entry
        // 3 days ago. The streak should stop counting at the gap: only the two most recent
        // consecutive days count, even though the total question count includes the older entry.
        let entries = [
            entry(daysAgo: 0),
            entry(daysAgo: 1),
            entry(daysAgo: 3)
        ]

        let digest = JournalDigest.compute(from: entries, calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 3)
        XCTAssertEqual(digest.currentStreak, 2)
    }

    func testComputeStreakAnchorsOnMostRecentEntryDayNotOnNow() {
        // Most recent entry is 5 days before `referenceDate` (e.g. the user hasn't asked
        // anything "today"). The streak still counts back from that most recent entry's day,
        // not from `now` — see `compute(from:)`'s doc comment.
        let entries = [
            entry(daysAgo: 5),
            entry(daysAgo: 6)
        ]

        let digest = JournalDigest.compute(from: entries, calendar: calendar, now: referenceDate)

        XCTAssertEqual(digest.questionCount, 2)
        XCTAssertEqual(digest.currentStreak, 2)
    }
}
