// FakeLanguageModelSession.swift
// ApinCoreTests
//
// Fake `LanguageModelSessionProviding` conformance used by
// `AssistantSessionServiceTests` (T4) so error-handling paths (timeout,
// unavailable, refusal, etc.) can be unit-tested without a live on-device
// FoundationModels session. Model *content* is deliberately not exercised here —
// only fixed/controlled strings and errors.

import Foundation
@testable import ApinCore

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
}
