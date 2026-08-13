// AssistantSessionServiceTests.swift
// ApinCoreTests
//
// Unit tests for T4's FoundationModels session wrapper. Exercises
// `AssistantSessionService` against `FakeLanguageModelSession` (a fake
// `LanguageModelSessionProviding` conformance) so error-handling paths (timeout,
// unavailable, refusal, etc.) are covered without a live on-device model. Model
// *content* is deliberately not tested here (non-deterministic) — only fixed
// strings and constructed errors.
//
// See tasks/task-graph.md T4. The "Structured (`sendStructured`)" section below
// covers Cycle 5's T2 additive guided-generation entry point the same way —
// structure/error-mapping only, no live-model content assertions.

import Foundation
import XCTest
@testable import ApinCore

#if canImport(FoundationModels)
import FoundationModels
#endif

private struct SomeOtherError: Error {}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
final class AssistantSessionServiceTests: XCTestCase {
    // MARK: - Success path (awaited)

    func testSendReturnsSessionResponseOnSuccess() async {
        let fake = FakeLanguageModelSession()
        fake.respondBehavior = .success("Here is the answer.")
        let service = AssistantSessionService(session: fake)

        let result = await service.send(prompt: "What is 2+2?")

        switch result {
        case .success(let text):
            XCTAssertEqual(text, "Here is the answer.")
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(fake.receivedPrompts, ["What is 2+2?"])
    }

    // MARK: - Timeout

    func testSendMapsHungSessionToTimeout() async {
        let fake = FakeLanguageModelSession()
        fake.respondBehavior = .hang
        let service = AssistantSessionService(session: fake, timeout: 0.05)

        let result = await service.send(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected timeout failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .timeout)
        }
    }

    // MARK: - Cancellation

    func testSendMapsTaskCancellationToCancelled() async {
        let fake = FakeLanguageModelSession()
        fake.respondBehavior = .hang
        let service = AssistantSessionService(session: fake, timeout: 5)

        let task = Task { await service.send(prompt: "q") }
        task.cancel()
        let result = await task.value

        switch result {
        case .success:
            XCTFail("Expected cancellation failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .cancelled)
        }
    }

    // MARK: - Unknown/other error

    func testSendMapsUnrecognizedErrorToOther() async {
        let fake = FakeLanguageModelSession()
        fake.respondBehavior = .failure(SomeOtherError())
        let service = AssistantSessionService(session: fake)

        let result = await service.send(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .other)
        }
    }

    // MARK: - Streaming

    func testStreamResponseYieldsPartialsInOrder() async throws {
        let fake = FakeLanguageModelSession()
        fake.streamValues = ["Hel", "Hello", "Hello world"]
        let service = AssistantSessionService(session: fake)

        var collected: [String] = []
        for try await partial in service.streamResponse(prompt: "hi") {
            collected.append(partial)
        }

        XCTAssertEqual(collected, ["Hel", "Hello", "Hello world"])
    }

    func testStreamResponseMapsUnrecognizedErrorToAssistantResponseError() async {
        let fake = FakeLanguageModelSession()
        fake.streamValues = ["partial"]
        fake.streamFailure = SomeOtherError()
        let service = AssistantSessionService(session: fake)

        do {
            for try await _ in service.streamResponse(prompt: "hi") {}
            XCTFail("Expected stream to throw")
        } catch let error as AssistantResponseError {
            XCTAssertEqual(error.kind, .other)
        } catch {
            XCTFail("Expected AssistantResponseError, got \(error)")
        }
    }

    // MARK: - FoundationModels GenerationError mapping
    //
    // These construct real `LanguageModelSession.GenerationError` values (no live
    // session/model involved — just enum cases with a debug-only `Context`) to
    // verify the mapping is exhaustive and correct against the actual framework
    // type, per the task's guidance to write against the real API shape.

    #if canImport(FoundationModels)
    func testSendMapsAssetsUnavailableToModelUnavailable() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "assets missing")
        await assertSendMapsGenerationError(.assetsUnavailable(context), to: .modelUnavailable)
    }

    func testSendMapsGuardrailViolationToRefusal() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "blocked by guardrail")
        await assertSendMapsGenerationError(.guardrailViolation(context), to: .refusal)
    }

    func testSendMapsExplicitRefusalToRefusal() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "model declined")
        let refusal = LanguageModelSession.GenerationError.Refusal(transcriptEntries: [])
        await assertSendMapsGenerationError(.refusal(refusal, context), to: .refusal)
    }

    func testSendMapsRateLimitedToRateLimited() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "slow down")
        await assertSendMapsGenerationError(.rateLimited(context), to: .rateLimited)
    }

    func testSendMapsConcurrentRequestsToConcurrentRequests() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "already responding")
        await assertSendMapsGenerationError(.concurrentRequests(context), to: .concurrentRequests)
    }

    func testSendMapsExceededContextWindowSizeToContextWindowExceeded() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "too much transcript")
        await assertSendMapsGenerationError(.exceededContextWindowSize(context), to: .contextWindowExceeded)
    }

    func testSendMapsUnsupportedLanguageOrLocaleToUnsupportedLanguage() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "locale not supported")
        await assertSendMapsGenerationError(.unsupportedLanguageOrLocale(context), to: .unsupportedLanguage)
    }

    func testSendMapsDecodingFailureToDecodingFailure() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "bad content")
        await assertSendMapsGenerationError(.decodingFailure(context), to: .decodingFailure)
    }

    func testSendMapsUnsupportedGuideToOther() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "unsupported guide")
        await assertSendMapsGenerationError(.unsupportedGuide(context), to: .other)
    }

    private func assertSendMapsGenerationError(
        _ generationError: LanguageModelSession.GenerationError,
        to expectedKind: AssistantResponseError.Kind,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let fake = FakeLanguageModelSession()
        fake.respondBehavior = .failure(generationError)
        let service = AssistantSessionService(session: fake)

        let result = await service.send(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected failure", file: file, line: line)
        case .failure(let error):
            XCTAssertEqual(error.kind, expectedKind, file: file, line: line)
        }
    }

    // MARK: - Structured (Cycle 5's T2 `sendStructured(prompt:)`)
    //
    // Mirrors the plain-`String` coverage above: success path, error-mapping
    // (reusing `mapGenerationError`, which is unchanged), timeout, and
    // cancellation. Response *content* is a fixed stub, not exercised for
    // correctness — only that it round-trips through the seam unmodified.

    func testSendStructuredReturnsSessionResponseOnSuccess() async {
        let fake = FakeLanguageModelSession()
        let expected = AskResponse(
            answer: "The answer.",
            followUpQuestion: "Want to know more?",
            chips: ["Tell me more", "No thanks"],
            tags: ["general"]
        )
        fake.structuredRespondBehavior = .success(expected)
        let service = AssistantSessionService(session: fake)

        let result = await service.sendStructured(prompt: "What is 2+2?")

        switch result {
        case .success(let value):
            XCTAssertEqual(value, expected)
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(fake.receivedStructuredPrompts, ["What is 2+2?"])
    }

    func testSendStructuredMapsHungSessionToTimeout() async {
        let fake = FakeLanguageModelSession()
        fake.structuredRespondBehavior = .hang
        let service = AssistantSessionService(session: fake, timeout: 0.05)

        let result = await service.sendStructured(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected timeout failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .timeout)
        }
    }

    func testSendStructuredMapsTaskCancellationToCancelled() async {
        let fake = FakeLanguageModelSession()
        fake.structuredRespondBehavior = .hang
        let service = AssistantSessionService(session: fake, timeout: 5)

        let task = Task { await service.sendStructured(prompt: "q") }
        task.cancel()
        let result = await task.value

        switch result {
        case .success:
            XCTFail("Expected cancellation failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .cancelled)
        }
    }

    func testSendStructuredMapsUnrecognizedErrorToOther() async {
        let fake = FakeLanguageModelSession()
        fake.structuredRespondBehavior = .failure(SomeOtherError())
        let service = AssistantSessionService(session: fake)

        let result = await service.sendStructured(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .other)
        }
    }

    func testSendStructuredMapsGuardrailViolationToRefusal() async {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "blocked by guardrail")
        let fake = FakeLanguageModelSession()
        fake.structuredRespondBehavior = .failure(LanguageModelSession.GenerationError.guardrailViolation(context))
        let service = AssistantSessionService(session: fake)

        let result = await service.sendStructured(prompt: "q")

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error.kind, .refusal)
        }
    }
    #endif
}
