// JournalExcerpt.swift
// ApinCore
//
// T3 — plain, testable computation of a first-sentence excerpt from a `JournalEntry.answer`
// string, for a later cycle's Journal row recreation to render as a preview without loading the
// full answer text. Deliberately a free-standing static function (not a view model, no SwiftUI
// import) so it's unit-testable without spinning up a SwiftData container or a view, mirroring
// `JournalDigest.compute(from:)`'s pattern.
//
// Computed on demand at render/query time — never persisted. No stored property was added to
// `JournalEntry`; callers derive the excerpt from an already-fetched `JournalEntry.answer`.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// Derives a first-sentence excerpt from a journal answer string.
@available(macOS 14, *)
public enum JournalExcerpt {
    /// Sentence-terminating characters this function splits on: `.`, `!`, `?`.
    private static let terminators: Set<Character> = [".", "!", "?"]

    /// Returns the first sentence of `answer`, trimmed of leading/trailing whitespace and
    /// newlines.
    ///
    /// **Rule**: scans `answer` (after trimming leading/trailing whitespace and newlines) for
    /// the first occurrence of `.`, `!`, or `?` that is immediately followed by whitespace or by
    /// the end of the string. The excerpt is everything from the start of the trimmed string up
    /// to and including that terminator. This avoids splitting mid-token on a `.` that is
    /// immediately followed by a non-whitespace character (e.g. the `.` inside a decimal number
    /// like "4.5"), but it is a deliberately simple, deterministic rule — not NLP sentence
    /// tokenization, and it does not special-case abbreviations like "e.g." whose trailing `.`
    /// is itself followed by whitespace (that `.` is treated as a sentence boundary, same as any
    /// other).
    ///
    /// **Fallback behavior** (no terminator found, e.g. a sentence-less answer with no terminal
    /// punctuation at all): returns the entire trimmed string as-is, rather than truncating or
    /// appending an ellipsis. Truncating to an arbitrary length isn't "first sentence" and would
    /// need a length parameter this function doesn't take; returning the full trimmed string is
    /// the least surprising behavior for a short answer that simply lacks punctuation.
    ///
    /// **Empty/blank input**: an empty string, or a string that is entirely whitespace/newlines,
    /// returns `""`.
    ///
    /// - Parameter answer: Typically `JournalEntry.answer`.
    /// - Returns: The first-sentence excerpt, or `""` for empty/blank input.
    public static func firstSentence(from answer: String) -> String {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        let characters = Array(trimmed)
        for index in characters.indices where terminators.contains(characters[index]) {
            let nextIndex = characters.index(after: index)
            let isFollowedByWhitespaceOrEnd = nextIndex == characters.endIndex
                || characters[nextIndex].isWhitespace
            if isFollowedByWhitespaceOrEnd {
                return String(characters[characters.startIndex...index])
            }
        }

        return trimmed
    }
}
