// AssistantSessionProviding.swift
// Apin
//
// Minimal seam `AskViewModel` (T7) needs from an assistant session — mirrors
// `AssistantSessionService`'s (T4) public API exactly. Declared here, in the app
// target, rather than in ApinCore, because T7 is scoped to `Features/Ask` only and
// must not edit ApinCore; `AssistantSessionService` already has matching method
// signatures, so the extension below is a zero-code retroactive conformance, not a
// reimplementation.
//
// Lets `AskViewModelTests` inject a fake session without depending on a live
// on-device FoundationModels session (same rationale as T4's own
// `LanguageModelSessionProviding` seam, one level up the stack).
//
// See tasks/task-graph.md T7.

import ApinCore

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
protocol AssistantSessionProviding: Sendable {
    /// Sends `prompt` and awaits the full response. Matches
    /// `AssistantSessionService.send(prompt:)`.
    func send(prompt: String) async -> Result<String, AssistantResponseError>

    /// Sends `prompt` and returns a stream of cumulative partial responses. Matches
    /// `AssistantSessionService.streamResponse(prompt:)`.
    func streamResponse(prompt: String) -> AsyncThrowingStream<String, Error>
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension AssistantSessionService: AssistantSessionProviding {}
