// FoundationModelsSessionAdapter.swift
// ApinCore
//
// Production conformance of `LanguageModelSessionProviding` that wraps Apple's
// on-device `LanguageModelSession` from the `FoundationModels` framework. This is
// the only file in the AI module that talks to the real framework's session type
// directly — `AssistantSessionService` is written entirely against the
// `LanguageModelSessionProviding` seam so it can be exercised with a fake in
// tests.
//
// See tasks/task-graph.md T4. Does not build the system-instructions content
// itself (T5) and does not build any UI (T7). `respondStructured(to:)` (Cycle
// 5's T2) additively wraps `LanguageModelSession.respond(to:generating:)` for
// guided generation.

import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// Wraps a real, on-device `LanguageModelSession`.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public final class FoundationModelsSessionAdapter: LanguageModelSessionProviding, @unchecked Sendable {
    private let session: LanguageModelSession

    /// Creates a session backed by the on-device system language model.
    /// - Parameter instructions: A system-instruction string to prime the
    ///   session with. Any source works — e.g. T5's personality builder's output
    ///   string — this type only requires a plain `String`, so it never imports
    ///   T5's concrete builder type.
    public init(instructions: String) {
        self.session = LanguageModelSession(instructions: instructions)
    }

    public func respond(to prompt: String) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }

    public func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error> {
        let session = self.session
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await snapshot in session.streamResponse(to: prompt) {
                        continuation.yield(snapshot.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Sends `prompt` and awaits a structured `AskResponse`, via
    /// `LanguageModelSession.respond(to:generating:)` (guided generation).
    /// Signature/macro syntax verified against this machine's real Xcode 26.6
    /// `FoundationModels.framework` `.swiftinterface` — see `AskResponse.swift`.
    public func respondStructured(to prompt: String) async throws -> AskResponse {
        let response = try await session.respond(to: prompt, generating: AskResponse.self)
        return response.content
    }
}
#endif
