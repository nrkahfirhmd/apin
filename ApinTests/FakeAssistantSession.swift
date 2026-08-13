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
// Cycle 5 T2 added `sendStructured(prompt:)` to `AssistantSessionProviding`
// (mirroring `AssistantSessionService`'s additive guided-generation entry point);
// `structuredBehavior` below is this fake's conformance to that new requirement,
// same success/failure shape as `sendBehavior`. No existing test exercises this
// yet — the consumer of structured output (follow-up chips, message history) is
// still deferred — but the fake must conform for this file to compile.
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

    #if canImport(FoundationModels)
    enum StructuredBehavior {
        case success(AskResponse)
        case failure(AssistantResponseError)
    }

    var structuredBehavior: StructuredBehavior = .success(
        AskResponse(answer: "stub answer", followUpQuestion: "stub follow-up?", chips: [], tags: [])
    )
    private(set) var receivedStructuredPrompts: [String] = []
    #endif

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

    #if canImport(FoundationModels)
    func sendStructured(prompt: String) async -> Result<AskResponse, AssistantResponseError> {
        receivedStructuredPrompts.append(prompt)
        switch structuredBehavior {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error)
        }
    }
    #endif
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension FakeAssistantSession: AskAndSaveServicing {
    func streamAndSave(prompt: String) -> AsyncThrowingStream<String, Error> {
        streamResponse(prompt: prompt)
    }
}
