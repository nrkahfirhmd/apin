// AskAndSaveServiceTests.swift
// ApinTests
//
// Unit tests for T8's `AskAndSaveService` — the shared "ask a question -> run the
// model -> save to the journal" orchestration point `AskViewModel` calls into (and
// that T13/T17 will converge on later). Exercises the two acceptance-criteria
// behaviors directly, independent of `AskViewModel`/SwiftUI: a successful ask
// saves exactly one `JournalEntry`, and a failed ask saves nothing. Uses
// `FakeAssistantSession` (the "fake wrapper") and `FakeJournalRepository` (the
// "fake repository") per the task's testing strategy.
//
// See tasks/task-graph.md T8.

import ApinCore
import XCTest
@testable import Apin

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
final class AskAndSaveServiceTests: XCTestCase {
    // MARK: - Success path

    func testSuccessfulStreamSavesExactlyOneEntry() async throws {
        let session = FakeAssistantSession()
        session.streamValues = ["Hel", "Hello", "Hello there"]
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        var received: [String] = []
        for try await partial in service.streamAndSave(prompt: "hi") {
            received.append(partial)
        }

        XCTAssertEqual(received, ["Hel", "Hello", "Hello there"])
        XCTAssertEqual(repository.savedEntries.count, 1)
        XCTAssertEqual(repository.savedEntries.first?.question, "hi")
        XCTAssertEqual(repository.savedEntries.first?.answer, "Hello there")
    }

    func testSuccessfulStreamSavesOnlyTheLastEmittedValueAsTheAnswer() async throws {
        let session = FakeAssistantSession()
        session.streamValues = ["a", "ab", "abc"]
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        for try await _ in service.streamAndSave(prompt: "q") {}

        XCTAssertEqual(repository.savedEntries.map(\.answer), ["abc"])
    }

    // MARK: - Failure path

    func testFailedStreamSavesNothing() async {
        let session = FakeAssistantSession()
        session.streamValues = ["partial"]
        session.streamFailure = AssistantResponseError(kind: .refusal, debugDescription: "declined")
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        var thrown: Error?
        do {
            for try await _ in service.streamAndSave(prompt: "hi") {}
        } catch {
            thrown = error
        }

        XCTAssertNotNil(thrown)
        XCTAssertTrue(repository.savedEntries.isEmpty)
    }

    func testFailedStreamRethrowsTheOriginalError() async {
        let session = FakeAssistantSession()
        session.streamFailure = AssistantResponseError(kind: .timeout, debugDescription: "took too long")
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        var thrown: AssistantResponseError?
        do {
            for try await _ in service.streamAndSave(prompt: "hi") {}
        } catch let error as AssistantResponseError {
            thrown = error
        } catch {
            XCTFail("Expected AssistantResponseError, got \(error)")
        }

        XCTAssertEqual(thrown?.kind, .timeout)
    }

    // MARK: - Repository failure

    func testRepositorySaveFailurePropagatesAsThrownErrorFromTheStream() async {
        struct SomePersistenceError: Error {}

        let session = FakeAssistantSession()
        session.streamValues = ["ok"]
        let repository = FakeJournalRepository()
        repository.saveError = SomePersistenceError()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        var thrown: Error?
        do {
            for try await _ in service.streamAndSave(prompt: "hi") {}
        } catch {
            thrown = error
        }

        XCTAssertNotNil(thrown)
        XCTAssertTrue(repository.savedEntries.isEmpty)
    }

    // MARK: - Auto-tags seeding (Cycle 5 T4)

    #if canImport(FoundationModels)
    func testSuccessfulStructuredCallSeedsSavedEntryTags() async throws {
        let session = FakeAssistantSession()
        session.streamValues = ["Hello there"]
        session.structuredBehavior = .success(
            AskResponse(
                answer: "Hello there",
                followUpQuestion: "anything else?",
                chips: [],
                tags: ["gratitude", "morning"]
            )
        )
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        for try await _ in service.streamAndSave(prompt: "hi") {}

        XCTAssertEqual(repository.savedEntries.count, 1)
        XCTAssertEqual(repository.savedEntries.first?.tags, ["gratitude", "morning"])
    }

    func testFailedStructuredCallSavesEntryWithEmptyTagsAndDoesNotFailTheStream() async throws {
        let session = FakeAssistantSession()
        session.streamValues = ["Hello there"]
        session.structuredBehavior = .failure(AssistantResponseError(kind: .refusal, debugDescription: "declined"))
        let repository = FakeJournalRepository()
        let service = AskAndSaveService(assistantSession: session, journalRepository: repository)

        var received: [String] = []
        for try await partial in service.streamAndSave(prompt: "hi") {
            received.append(partial)
        }

        XCTAssertEqual(received, ["Hello there"])
        XCTAssertEqual(repository.savedEntries.count, 1)
        XCTAssertEqual(repository.savedEntries.first?.answer, "Hello there")
        XCTAssertEqual(repository.savedEntries.first?.tags, [])
    }
    #endif
}
