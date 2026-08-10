// AskAndSaveServicing.swift
// Apin
//
// T8 — the narrow seam `AskViewModel` depends on for "ask a question, stream the
// answer, and save it to the journal on success." `AskAndSaveService` is the real,
// production conformance; tests inject a fake so `AskViewModel`'s phase transitions
// stay testable without a live assistant session or a real journal store.
//
// See tasks/task-graph.md T8.

import ApinCore

/// Streams an answer for `prompt` and — once (and only once) the stream completes
/// without error — persists the resulting question/answer pair as a new
/// `JournalEntry`. A failed/errored ask (the stream throws) must not save anything.
///
/// `@MainActor`-isolated to match `JournalRepository` (T6), which SwiftData's
/// `ModelContext` affinity requires.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
protocol AskAndSaveServicing {
    /// Same cumulative-partial-string streaming shape as
    /// `AssistantSessionProviding.streamResponse(prompt:)` — conformers are free to
    /// wrap that call directly. The stream's *last* emitted value is what gets
    /// saved as the entry's `answer` once the stream finishes successfully.
    func streamAndSave(prompt: String) -> AsyncThrowingStream<String, Error>
}
