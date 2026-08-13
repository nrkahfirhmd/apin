// JournalExcerptTests.swift
// ApinCoreTests
//
// Unit tests for T3's `JournalExcerpt.firstSentence(from:)`. Pure string computation — no
// `JournalEntry`/SwiftData needed. Covers the acceptance criteria's four required cases:
// empty/blank answer, single-sentence answer, multi-sentence answer (stops at the first
// sentence boundary), and a sentence-less answer with no terminal punctuation (fallback).

import XCTest
@testable import ApinCore

@available(macOS 14, *)
final class JournalExcerptTests: XCTestCase {
    // MARK: - Empty / blank answer

    func testFirstSentenceWithEmptyStringReturnsEmptyString() {
        XCTAssertEqual(JournalExcerpt.firstSentence(from: ""), "")
    }

    func testFirstSentenceWithWhitespaceOnlyStringReturnsEmptyString() {
        XCTAssertEqual(JournalExcerpt.firstSentence(from: "   \n\t  "), "")
    }

    // MARK: - Single-sentence answer

    func testFirstSentenceWithSingleSentenceReturnsWholeSentence() {
        let answer = "The mitochondria is the powerhouse of the cell."

        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: answer),
            "The mitochondria is the powerhouse of the cell."
        )
    }

    func testFirstSentenceWithSingleSentenceTrimsSurroundingWhitespace() {
        let answer = "  \n Paris is the capital of France. \n  "

        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: answer),
            "Paris is the capital of France."
        )
    }

    // MARK: - Multi-sentence answer

    func testFirstSentenceWithMultipleSentencesStopsAtFirstBoundary() {
        let answer = "Water boils at 100 degrees Celsius. This is at sea-level pressure. " +
            "Altitude changes this."

        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: answer),
            "Water boils at 100 degrees Celsius."
        )
    }

    func testFirstSentenceWithMultipleSentencesHandlesQuestionAndExclamationTerminators() {
        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: "Is that true? I'm not sure."),
            "Is that true?"
        )
        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: "Wow! That's surprising."),
            "Wow!"
        )
    }

    func testFirstSentenceDoesNotSplitOnPeriodNotFollowedByWhitespace() {
        // The "." inside "4.5" is immediately followed by "5" (non-whitespace), so the
        // documented rule does not treat it as a sentence boundary; the real sentence-ending
        // period (followed by end-of-string) is used instead.
        let answer = "It scored 4.5 out of 5 overall."

        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: answer),
            "It scored 4.5 out of 5 overall."
        )
    }

    // MARK: - Sentence-less answer (no terminal punctuation)

    func testFirstSentenceWithNoTerminalPunctuationReturnsFullTrimmedString() {
        let answer = "  just a fragment with no ending punctuation  "

        XCTAssertEqual(
            JournalExcerpt.firstSentence(from: answer),
            "just a fragment with no ending punctuation"
        )
    }
}
