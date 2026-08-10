// LanguageModelSessionProviding.swift
// ApinCore
//
// Protocol seam around FoundationModels' `LanguageModelSession` so
// `AssistantSessionService` (T4) can be unit-tested with a fake conformance
// instead of a live on-device model. `FoundationModelsSessionAdapter` is the
// production conformance backed by the real framework.
//
// See tasks/task-graph.md T4.

import Foundation

/// Minimal surface `AssistantSessionService` needs from a session. Kept
/// intentionally small (prompt in, text out — either awaited or streamed) so
/// fakes are trivial to write in tests.
///
/// Gated at iOS/macOS 26 to match `FoundationModels` itself (the type this
/// protocol stands in for), even though the protocol shape alone doesn't need
/// that high a floor — this keeps the whole AI module's availability story
/// consistent rather than partially gating pieces at 10.15/13.0 and others at 26.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public protocol LanguageModelSessionProviding: Sendable {
    /// Sends `prompt` and awaits the full response.
    func respond(to prompt: String) async throws -> String

    /// Sends `prompt` and returns a stream of cumulative partial responses.
    /// Matches FoundationModels' `streamResponse` snapshot semantics: each
    /// element is the full text generated so far, not a delta.
    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error>
}
