// JournalQueryTests.swift
// ApinCoreTests
//
// Unit tests for T10's `JournalQuery.search(keyword:dateRange:)` query-builder, extended by
// T11 with a `tag` filter, exercised against a real `SwiftDataJournalRepository` backed by an
// in-memory `ModelContainer` (per T10/T11's acceptance criteria: predicate/query-construction
// logic tested independent of SwiftUI). Covers keyword-only, date-range-only, tag-only, and
// combined (AND, not OR) filtering.

import XCTest
import SwiftData
@testable import ApinCore

@available(macOS 14, *)
@MainActor
final class JournalQueryTests: XCTestCase {
    private var repository: SwiftDataJournalRepository!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        repository = SwiftDataJournalRepository(modelContainer: container)
    }

    override func tearDownWithError() throws {
        repository = nil
    }

    // MARK: - Keyword

    func testSearchWithEmptyKeywordAndNoDateRangeReturnsAllEntries() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language"))
        try await repository.save(JournalEntry(question: "about rust", answer: "another language"))

        let results = try await repository.fetch(matching: .search(keyword: ""))

        XCTAssertEqual(results.count, 2)
    }

    func testSearchWithWhitespaceOnlyKeywordIsTreatedAsNoKeywordFilter() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language"))

        let results = try await repository.fetch(matching: .search(keyword: "   "))

        XCTAssertEqual(results.count, 1)
    }

    func testSearchMatchesKeywordInQuestionCaseInsensitively() async throws {
        try await repository.save(JournalEntry(question: "What is Spaced Repetition?", answer: "A study technique"))
        try await repository.save(JournalEntry(question: "What is Rust?", answer: "A language"))

        let results = try await repository.fetch(matching: .search(keyword: "repetition"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "What is Spaced Repetition?")
    }

    func testSearchMatchesKeywordInAnswerCaseInsensitively() async throws {
        try await repository.save(JournalEntry(question: "Q1", answer: "The mitochondria is the powerhouse"))
        try await repository.save(JournalEntry(question: "Q2", answer: "Something unrelated"))

        let results = try await repository.fetch(matching: .search(keyword: "MITOCHONDRIA"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "Q1")
    }

    func testSearchWithNoMatchingKeywordReturnsEmpty() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language"))

        let results = try await repository.fetch(matching: .search(keyword: "nonexistent"))

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Date range

    func testSearchWithDateRangeOnlyNarrowsToEntriesWithinRange() async throws {
        let inRange = JournalEntry(question: "in range", answer: "a", createdAt: Date(timeIntervalSince1970: 1_000))
        let beforeRange = JournalEntry(question: "before", answer: "b", createdAt: Date(timeIntervalSince1970: 0))
        let afterRange = JournalEntry(question: "after", answer: "c", createdAt: Date(timeIntervalSince1970: 5_000))
        try await repository.save(inRange)
        try await repository.save(beforeRange)
        try await repository.save(afterRange)

        let range = Date(timeIntervalSince1970: 500)...Date(timeIntervalSince1970: 2_000)
        let results = try await repository.fetch(matching: .search(keyword: "", dateRange: range))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "in range")
    }

    func testSearchDateRangeBoundsAreInclusive() async throws {
        let lower = Date(timeIntervalSince1970: 1_000)
        let upper = Date(timeIntervalSince1970: 2_000)
        try await repository.save(JournalEntry(question: "at lower bound", answer: "a", createdAt: lower))
        try await repository.save(JournalEntry(question: "at upper bound", answer: "b", createdAt: upper))

        let results = try await repository.fetch(matching: .search(keyword: "", dateRange: lower...upper))

        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Combined keyword + date range (AND, not OR)

    func testSearchCombinesKeywordAndDateRangeWithAND() async throws {
        let matchesBoth = JournalEntry(
            question: "about swift",
            answer: "a language",
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let matchesKeywordOnly = JournalEntry(
            question: "about swift",
            answer: "a language",
            createdAt: Date(timeIntervalSince1970: 9_000)
        )
        let matchesDateOnly = JournalEntry(
            question: "about rust",
            answer: "another language",
            createdAt: Date(timeIntervalSince1970: 1_500)
        )
        try await repository.save(matchesBoth)
        try await repository.save(matchesKeywordOnly)
        try await repository.save(matchesDateOnly)

        let range = Date(timeIntervalSince1970: 500)...Date(timeIntervalSince1970: 2_000)
        let results = try await repository.fetch(matching: .search(keyword: "swift", dateRange: range))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "about swift")
        XCTAssertEqual(results.first?.createdAt, matchesBoth.createdAt)
    }

    func testSearchSortOrderDefaultsToReverseChronological() async throws {
        let older = JournalEntry(question: "older swift", answer: "a", createdAt: Date(timeIntervalSince1970: 0))
        let newer = JournalEntry(question: "newer swift", answer: "b", createdAt: Date(timeIntervalSince1970: 1_000))
        try await repository.save(older)
        try await repository.save(newer)

        let results = try await repository.fetch(matching: .search(keyword: "swift"))

        XCTAssertEqual(results.map(\.question), ["newer swift", "older swift"])
    }

    // MARK: - Tag (T11)

    func testSearchWithNilTagAndNoOtherFiltersReturnsAllEntries() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language", tags: ["dev"]))
        try await repository.save(JournalEntry(question: "about rust", answer: "another language"))

        let results = try await repository.fetch(matching: .search(keyword: "", tag: nil))

        XCTAssertEqual(results.count, 2)
    }

    func testSearchWithWhitespaceOnlyTagIsTreatedAsNoTagFilter() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language", tags: ["dev"]))

        let results = try await repository.fetch(matching: .search(keyword: "", tag: "   "))

        XCTAssertEqual(results.count, 1)
    }

    func testSearchWithTagOnlyNarrowsToEntriesContainingTag() async throws {
        let tagged = JournalEntry(question: "about swift", answer: "a language", tags: ["dev", "learning"])
        let untagged = JournalEntry(question: "about rust", answer: "another language")
        try await repository.save(tagged)
        try await repository.save(untagged)

        let results = try await repository.fetch(matching: .search(keyword: "", tag: "dev"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "about swift")
    }

    func testSearchTagMatchIsExactNotSubstring() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language", tags: ["development"]))

        let results = try await repository.fetch(matching: .search(keyword: "", tag: "dev"))

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchWithNoMatchingTagReturnsEmpty() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language", tags: ["dev"]))

        let results = try await repository.fetch(matching: .search(keyword: "", tag: "nonexistent"))

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Combined keyword + tag + date range (AND, not OR)

    func testSearchCombinesTagWithKeywordWithAND() async throws {
        let matchesBoth = JournalEntry(question: "about swift", answer: "a language", tags: ["dev"])
        let matchesKeywordOnly = JournalEntry(question: "about swift", answer: "a language", tags: ["other"])
        let matchesTagOnly = JournalEntry(question: "about rust", answer: "another language", tags: ["dev"])
        try await repository.save(matchesBoth)
        try await repository.save(matchesKeywordOnly)
        try await repository.save(matchesTagOnly)

        let results = try await repository.fetch(matching: .search(keyword: "swift", tag: "dev"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "about swift")
        XCTAssertEqual(results.first?.tags, ["dev"])
    }

    func testSearchCombinesTagKeywordAndDateRangeWithAND() async throws {
        let matchesAll = JournalEntry(
            question: "about swift",
            answer: "a language",
            createdAt: Date(timeIntervalSince1970: 1_000),
            tags: ["dev"]
        )
        let missesDateRange = JournalEntry(
            question: "about swift",
            answer: "a language",
            createdAt: Date(timeIntervalSince1970: 9_000),
            tags: ["dev"]
        )
        let missesTag = JournalEntry(
            question: "about swift",
            answer: "a language",
            createdAt: Date(timeIntervalSince1970: 1_500),
            tags: ["other"]
        )
        try await repository.save(matchesAll)
        try await repository.save(missesDateRange)
        try await repository.save(missesTag)

        let range = Date(timeIntervalSince1970: 500)...Date(timeIntervalSince1970: 2_000)
        let results = try await repository.fetch(matching: .search(keyword: "swift", dateRange: range, tag: "dev"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.createdAt, matchesAll.createdAt)
    }
}
