// ApinWidgetEntryTests.swift
// ApinWidgetTests
//
// Unit tests for `ApinWidgetEntry.make(from:)` (T16) -- the widget's pure, deterministic
// mapping from a fetched `JournalEntry` to what the timeline renders. This test target
// compiles `ApinWidget/ApinWidgetEntry.swift` and `ApinWidget/JournalWidgetStore.swift`
// directly (see `project.yml`) rather than depending on the `ApinWidgetExtension` app
// extension as a test host, since app extensions don't support hosted XCTest bundles the
// way the `Apin` app target does.

import ApinCore
import XCTest

final class ApinWidgetEntryTests: XCTestCase {
    func test_make_fromNilEntry_returnsEmpty() {
        let entry = ApinWidgetEntry.make(from: nil)

        XCTAssertFalse(entry.hasEntry)
        XCTAssertEqual(entry.question, "")
        XCTAssertEqual(entry.answerSnippet, "")
        XCTAssertNil(entry.createdAt)
    }

    func test_make_fromJournalEntry_mapsFields() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let journalEntry = JournalEntry(
            question: "What's the capital of Indonesia?",
            answer: "Jakarta.",
            createdAt: createdAt
        )

        let entry = ApinWidgetEntry.make(from: journalEntry)

        XCTAssertTrue(entry.hasEntry)
        XCTAssertEqual(entry.question, "What's the capital of Indonesia?")
        XCTAssertEqual(entry.answerSnippet, "Jakarta.")
        XCTAssertEqual(entry.createdAt, createdAt)
    }

    func test_make_truncatesLongAnswerToSnippetLength() {
        let longAnswer = String(repeating: "a", count: 500)
        let journalEntry = JournalEntry(question: "Q", answer: longAnswer)

        let entry = ApinWidgetEntry.make(from: journalEntry, answerSnippetLength: 140)

        XCTAssertEqual(entry.answerSnippet.count, 140)
    }

    func test_placeholder_hasEntry() {
        XCTAssertTrue(ApinWidgetEntry.placeholder.hasEntry)
    }

    func test_empty_doesNotHaveEntry() {
        XCTAssertFalse(ApinWidgetEntry.empty.hasEntry)
    }
}
