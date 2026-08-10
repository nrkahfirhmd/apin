// JournalEntryDetailViewTests.swift
// ApinTests
//
// Unit tests for T11's `JournalEntryDetailView.formattedTimestamp(_:calendar:)` — the only
// non-trivial logic this task adds (everything else is straight SwiftUI layout). Uses a fixed
// calendar/time zone/locale so the formatted output is deterministic regardless of the host
// machine's settings. See tasks/task-graph.md T11.

import XCTest
@testable import Apin

final class JournalEntryDetailViewTests: XCTestCase {
    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    func testFormattedTimestampIncludesLongDateAndTime() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 10
        components.hour = 15
        components.minute = 45
        let calendar = utcCalendar()
        let date = calendar.date(from: components)!

        let formatted = JournalEntryDetailView.formattedTimestamp(date, calendar: calendar)

        XCTAssertTrue(formatted.contains("2026"), "Expected year in \(formatted)")
        XCTAssertTrue(formatted.contains("August"), "Expected long month name in \(formatted)")
        XCTAssertTrue(formatted.contains("10"), "Expected day in \(formatted)")
    }

    func testFormattedTimestampIsDeterministicForSameInput() {
        let calendar = utcCalendar()
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 9, minute: 0))!

        let first = JournalEntryDetailView.formattedTimestamp(date, calendar: calendar)
        let second = JournalEntryDetailView.formattedTimestamp(date, calendar: calendar)

        XCTAssertEqual(first, second)
    }
}
