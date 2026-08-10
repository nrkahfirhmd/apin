// FakeAssistantSession.swift
// ApinTests
//
// Fake `AssistantSessionProviding` conformance used by `AskViewModelTests` (T7) so
// state transitions (loading -> streaming -> answered/failed) can be unit-tested
// without a live on-device FoundationModels session. Mirrors the shape of
// ApinCoreTests' `FakeLanguageModelSession` one layer up the stack. Model *content*
// is deliberately not exercised here — only fixed/controlled strings and errors.
//
// T8: also given a trivial `AskAndSaveServicing` conformance (`streamAndSave` just
// forwards to `streamResponse`, no save) so `AskViewModelTests` can keep injecting
// this directly wherever `AskViewModel` needs an `AskAndSaveServicing` — those
// tests exercise phase transitions, not save behavior. Save behavior itself is
// covered separately by `AskAndSaveServiceTests` against `FakeJournalRepository`.
//
// See tasks/task-graph.md T7, T8.

import ApinCore
import Foundation
@testable import Apin

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
final class FakeAssistantSession: AssistantSessionProviding, @unchecked Sendable {
    enum SendBehavior {
        case success(String)
        case failure(AssistantResponseError)
    }

    var sendBehavior: SendBehavior = .success("stub response")
    var streamValues: [String] = []
    var streamFailure: AssistantResponseError?

    private(set) var receivedPrompts: [String] = []

    func send(prompt: String) async -> Result<String, AssistantResponseError> {
        receivedPrompts.append(prompt)
        switch sendBehavior {
        case .success(let text):
            return .success(text)
        case .failure(let error):
            return .failure(error)
        }
    }

    func streamResponse(prompt: String) -> AsyncThrowingStream<String, Error> {
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

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension FakeAssistantSession: AskAndSaveServicing {
    func streamAndSave(prompt: String) -> AsyncThrowingStream<String, Error> {
        streamResponse(prompt: prompt)
    }
}
