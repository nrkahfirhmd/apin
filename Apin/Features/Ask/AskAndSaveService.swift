// AskAndSaveService.swift
// Apin
//
// T8 — the single reusable "ask a question -> run the model -> save the Q&A pair
// to the journal" orchestration point. `AskViewModel` (T7) calls into this rather
// than doing the model-call + save inline itself, per this task's scope: T13's
// `AskApinIntent` and T17's widget quick-ask both need this exact same flow and
// must not each reimplement it.
//
// IMPORTANT for T13/T17 (read before wiring either up):
//   - Per tasks/task-graph.md, both T13 and T17 are scoped to *deep-link into the
//     app and prefill `AskView`'s query* (via T7's existing `prefilledQuery`/
//     `prefill(with:)` seam) rather than invoking model + save logic themselves —
//     once the app opens, the normal Ask screen flow (`AskView` -> `AskViewModel`
//     -> this service) produces and saves the answer, so there is only ever one
//     code path that actually asks + saves.
//   - This type currently lives in the app target (not `ApinCore`) because it
//     depends on `AssistantSessionProviding`, which is intentionally app-target-
//     scoped (see that file's header). If a future task needs to call this
//     service *directly* from `ApinCore` (e.g. from an `AppIntent` that does not
//     go through the app UI at all, bypassing `AskViewModel`), it will need to
//     relocate this orchestration (and `AssistantSessionProviding`) into
//     `ApinCore` at that point — flagging this now rather than guessing at that
//     future shape.
//
// See tasks/task-graph.md T8, T13, T17.

import ApinCore

/// Production `AskAndSaveServicing` conformance: wraps an `AssistantSessionProviding`
/// (T4's session, seen through T7's seam) and a `JournalRepository` (T6).
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
final class AskAndSaveService: AskAndSaveServicing {
    private let assistantSession: AssistantSessionProviding
    private let journalRepository: JournalRepository

    init(assistantSession: AssistantSessionProviding, journalRepository: JournalRepository) {
        self.assistantSession = assistantSession
        self.journalRepository = journalRepository
    }

    /// Forwards `assistantSession.streamResponse(prompt:)`'s cumulative partial
    /// values unchanged (so a streaming UI sees identical incremental output), and
    /// — only if/when the upstream stream finishes without throwing — saves a new
    /// `JournalEntry(question: prompt, answer: <last emitted value>)` before
    /// finishing this stream. If the upstream stream throws, no entry is saved and
    /// the same error is rethrown unchanged. If the save itself throws (e.g. a
    /// SwiftData persistence failure), that error is thrown from this stream too —
    /// callers (like `AskViewModel`) already map any thrown error to a `.failed`
    /// phase, so this doesn't require special-casing at call sites.
    func streamAndSave(prompt: String) -> AsyncThrowingStream<String, Error> {
        let upstream = assistantSession.streamResponse(prompt: prompt)
        return AsyncThrowingStream { continuation in
            let task = Task { @MainActor [journalRepository] in
                do {
                    var latest = ""
                    for try await partial in upstream {
                        latest = partial
                        continuation.yield(partial)
                    }
                    try await journalRepository.save(JournalEntry(question: prompt, answer: latest))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
