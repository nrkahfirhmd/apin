// FakeLanguageModelSession.swift
// ApinCoreTests
//
// Fake `LanguageModelSessionProviding` conformance used by
// `AssistantSessionServiceTests` (T4) so error-handling paths (timeout,
// unavailable, refusal, etc.) can be unit-tested without a live on-device
// FoundationModels session. Model *content* is deliberately not exercised here —
// only fixed/controlled strings and errors. `structuredRespondBehavior` (Cycle
// 5's T2) extends this the same way for `respondStructured(to:)`.

import Foundation
@testable import ApinCore

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
final class FakeLanguageModelSession: LanguageModelSessionProviding, @unchecked Sendable {
    enum RespondBehavior {
        case success(String)
        case failure(Error)
        /// Never returns within any reasonable test timeout, to exercise
        /// `AssistantSessionService`'s own timeout enforcement.
        case hang
    }

    var respondBehavior: RespondBehavior = .success("stub response")
    var streamValues: [String] = []
    var streamFailure: Error?

    private(set) var receivedPrompts: [String] = []

    func respond(to prompt: String) async throws -> String {
        receivedPrompts.append(prompt)
        switch respondBehavior {
        case .success(let text):
            return text
        case .failure(let error):
            throw error
        case .hang:
            try await Task.sleep(nanoseconds: .max)
            return "" // unreachable in practice; satisfies the return type.
        }
    }

    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error> {
        receivedPrompts.append(prompt)
        return AsyncThrowingStream { continuation in
            for value in streamValues {
                continuation.yield(value)
            }
            if let streamFailure {
                continuation.finish(throwing: streamFailure)
            } else {
                continuation.finish()
            }
        }
    }

    #if canImport(FoundationModels)
    enum StructuredRespondBehavior {
        case success(AskResponse)
        case failure(Error)
        /// Never returns within any reasonable test timeout, to exercise
        /// `AssistantSessionService`'s own timeout enforcement.
        case hang
    }

    var structuredRespondBehavior: StructuredRespondBehavior = .success(
        AskResponse(
            answer: "stub answer",
            followUpQuestion: "stub follow-up?",
            chips: ["chip a", "chip b"],
            tags: ["stub"]
        )
    )

    private(set) var receivedStructuredPrompts: [String] = []

    func respondStructured(to prompt: String) async throws -> AskResponse {
        receivedStructuredPrompts.append(prompt)
        switch structuredRespondBehavior {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .hang:
            try await Task.sleep(nanoseconds: .max)
            return AskResponse(answer: "", followUpQuestion: "", chips: [], tags: []) // unreachable in practice.
        }
    }
    #endif
}
