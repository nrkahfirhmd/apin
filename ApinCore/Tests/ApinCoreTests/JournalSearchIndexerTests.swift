// JournalSearchIndexerTests.swift
// ApinCoreTests
//
// Unit tests for T14: `JournalSearchIndexPayload` construction and `JournalSearchIndexer`
// (the `JournalEntrySaveSideEffect`/`JournalEntryDeleteSideEffect` conformance), exercised
// against `FakeJournalSearchIndexing` — no dependency on a live on-device Spotlight index.

import XCTest
import SwiftData
@testable import ApinCore

@available(macOS 14, *)
final class JournalSearchIndexerTests: XCTestCase {
    // MARK: - Payload construction

    @MainActor
    func testPayloadCopiesFieldsFromEntry() {
        let entry = JournalEntry(
            question: "Why is the sky blue?",
            answer: "Rayleigh scattering.",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let payload = JournalSearchIndexPayload(entry: entry)

        XCTAssertEqual(payload.id, entry.id)
        XCTAssertEqual(payload.question, entry.question)
        XCTAssertEqual(payload.answer, entry.answer)
        XCTAssertEqual(payload.createdAt, entry.createdAt)
    }

    // MARK: - Save hook -> index

    @MainActor
    func testJournalEntryDidSaveIndexesExactlyOneItemWithMappedFields() async {
        let fake = FakeJournalSearchIndexing()
        let indexer = JournalSearchIndexer(indexing: fake)
        let entry = JournalEntry(question: "What is 2+2?", answer: "4")

        await indexer.journalEntryDidSave(entry)

        XCTAssertEqual(fake.indexedPayloads.count, 1)
        XCTAssertEqual(fake.indexedPayloads.first?.id, entry.id)
        XCTAssertEqual(fake.indexedPayloads.first?.question, "What is 2+2?")
        XCTAssertEqual(fake.indexedPayloads.first?.answer, "4")
        XCTAssertTrue(fake.deletedIDs.isEmpty)
    }

    @MainActor
    func testSavingTheSameEntryTwiceIndexesTwiceKeyedBySameID() async {
        let fake = FakeJournalSearchIndexing()
        let indexer = JournalSearchIndexer(indexing: fake)
        let entry = JournalEntry(question: "Q", answer: "A")

        await indexer.journalEntryDidSave(entry)
        entry.answer = "updated answer"
        await indexer.journalEntryDidSave(entry)

        XCTAssertEqual(fake.indexedPayloads.count, 2)
        XCTAssertEqual(fake.indexedPayloads.map(\.id), [entry.id, entry.id])
        XCTAssertEqual(fake.indexedPayloads.last?.answer, "updated answer")
    }

    // MARK: - Delete hook -> remove indexed item

    func testJournalEntryDidDeleteRemovesExactlyOneIndexedItem() async {
        let fake = FakeJournalSearchIndexing()
        let indexer = JournalSearchIndexer(indexing: fake)
        let id = UUID()

        await indexer.journalEntryDidDelete(id: id)

        XCTAssertEqual(fake.deletedIDs, [id])
        XCTAssertTrue(fake.indexedPayloads.isEmpty)
    }

    // MARK: - Repository integration (the save/delete hooks)

    @MainActor
    func testSavingEntryViaRepositoryIndexesExactlyOneItem() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let fake = FakeJournalSearchIndexing()
        let repository = SwiftDataJournalRepository(
            modelContainer: container,
            saveSideEffects: [JournalSearchIndexer(indexing: fake)],
            deleteSideEffects: []
        )
        let entry = JournalEntry(question: "Repo hook question", answer: "Repo hook answer")

        try await repository.save(entry)

        XCTAssertEqual(fake.indexedPayloads.count, 1)
        XCTAssertEqual(fake.indexedPayloads.first?.id, entry.id)
        XCTAssertEqual(fake.indexedPayloads.first?.question, "Repo hook question")
        XCTAssertEqual(fake.indexedPayloads.first?.answer, "Repo hook answer")
    }

    @MainActor
    func testDeletingEntryViaRepositoryRemovesItsIndexedItem() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let fake = FakeJournalSearchIndexing()
        let repository = SwiftDataJournalRepository(
            modelContainer: container,
            saveSideEffects: [],
            deleteSideEffects: [JournalSearchIndexer(indexing: fake)]
        )
        let entry = JournalEntry(question: "to delete", answer: "bye")
        try await repository.save(entry)

        try await repository.delete(id: entry.id)

        XCTAssertEqual(fake.deletedIDs, [entry.id])
    }

    @MainActor
    func testDeletingNonexistentEntryDoesNotInvokeDeleteSideEffects() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let fake = FakeJournalSearchIndexing()
        let repository = SwiftDataJournalRepository(
            modelContainer: container,
            saveSideEffects: [],
            deleteSideEffects: [JournalSearchIndexer(indexing: fake)]
        )

        try await repository.delete(id: UUID())

        XCTAssertTrue(fake.deletedIDs.isEmpty)
    }

    @MainActor
    func testEmptyDeleteSideEffectsArrayInvokesNothing() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let repository = SwiftDataJournalRepository(
            modelContainer: container,
            saveSideEffects: [],
            deleteSideEffects: []
        )
        let entry = JournalEntry(question: "no side effects", answer: "nothing happens")
        try await repository.save(entry)

        // Should complete without throwing/crashing even with no delete side effects registered.
        try await repository.delete(id: entry.id)

        let fetched = try await repository.fetch(by: entry.id)
        XCTAssertNil(fetched)
    }
}
