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
// See tasks/task-graph.md T7. `sendStructured(prompt:)` (Cycle 5's T2) mirrors
// `AssistantSessionService`'s additive guided-generation entry point — the
// consumer of this new structured surface (follow-up chips, message history) is
// deferred to a later cycle; this file only mirrors the method signature, per
// this file's own stated design.

import ApinCore

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
protocol AssistantSessionProviding: Sendable {
    /// Sends `prompt` and awaits the full response. Matches
    /// `AssistantSessionService.send(prompt:)`.
    func send(prompt: String) async -> Result<String, AssistantResponseError>

    /// Sends `prompt` and returns a stream of cumulative partial responses. Matches
    /// `AssistantSessionService.streamResponse(prompt:)`.
    func streamResponse(prompt: String) -> AsyncThrowingStream<String, Error>

    #if canImport(FoundationModels)
    /// Sends `prompt` and awaits a structured `AskResponse`. Matches
    /// `AssistantSessionService.sendStructured(prompt:)`. Gated alongside
    /// `AskResponse` itself, which only exists when `FoundationModels` can be
    /// imported (see `ApinCore`'s `AskResponse.swift`).
    func sendStructured(prompt: String) async -> Result<AskResponse, AssistantResponseError>
    #endif
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension AssistantSessionService: AssistantSessionProviding {}
