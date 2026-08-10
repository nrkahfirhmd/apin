// JournalRepositoryTests.swift
// ApinCoreTests
//
// Unit tests for T6: `JournalEntry` + `SwiftDataJournalRepository`, using an in-memory
// `ModelContainer` so no state leaks between tests and nothing touches disk.

import XCTest
import SwiftData
@testable import ApinCore

@available(macOS 14, *)
@MainActor
final class JournalRepositoryTests: XCTestCase {
    private var repository: SwiftDataJournalRepository!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        repository = SwiftDataJournalRepository(modelContainer: container)
    }

    override func tearDownWithError() throws {
        repository = nil
    }

    // MARK: - Create / Read

    func testSavePersistsEntryRetrievableByFetchAll() async throws {
        let entry = JournalEntry(question: "What is 2+2?", answer: "4")

        try await repository.save(entry)
        let all = try await repository.fetchAll()

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, entry.id)
        XCTAssertEqual(all.first?.question, "What is 2+2?")
        XCTAssertEqual(all.first?.answer, "4")
    }

    func testFetchByIDReturnsMatchingEntry() async throws {
        let entry = JournalEntry(question: "Q1", answer: "A1")
        try await repository.save(entry)

        let fetched = try await repository.fetch(by: entry.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, entry.id)
    }

    func testFetchByIDReturnsNilWhenEntryDoesNotExist() async throws {
        let fetched = try await repository.fetch(by: UUID())

        XCTAssertNil(fetched)
    }

    func testFetchAllReturnsEmptyArrayWhenStoreIsEmpty() async throws {
        let all = try await repository.fetchAll()

        XCTAssertTrue(all.isEmpty)
    }

    func testFetchAllOrdersReverseChronologicallyByDefault() async throws {
        let older = JournalEntry(question: "older", answer: "a", createdAt: Date(timeIntervalSince1970: 0))
        let newer = JournalEntry(question: "newer", answer: "b", createdAt: Date(timeIntervalSince1970: 1000))
        try await repository.save(older)
        try await repository.save(newer)

        let all = try await repository.fetchAll()

        XCTAssertEqual(all.map(\.question), ["newer", "older"])
    }

    func testNewEntryDefaultsToEmptyTags() async throws {
        let entry = JournalEntry(question: "Q", answer: "A")
        try await repository.save(entry)

        let fetched = try await repository.fetch(by: entry.id)

        XCTAssertEqual(fetched?.tags, [])
    }

    // MARK: - Delete

    func testDeleteRemovesEntry() async throws {
        let entry = JournalEntry(question: "to delete", answer: "bye")
        try await repository.save(entry)

        try await repository.delete(id: entry.id)

        let fetched = try await repository.fetch(by: entry.id)
        XCTAssertNil(fetched)
        let all = try await repository.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testDeleteNonexistentIDIsANoOp() async throws {
        let entry = JournalEntry(question: "stays", answer: "here")
        try await repository.save(entry)

        try await repository.delete(id: UUID())

        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Query surface (future predicate-based filtering, e.g. T10)

    func testFetchMatchingAllIsEquivalentToFetchAll() async throws {
        let entry = JournalEntry(question: "Q", answer: "A")
        try await repository.save(entry)

        let viaFetchAll = try await repository.fetchAll()
        let viaQuery = try await repository.fetch(matching: .all)

        XCTAssertEqual(viaFetchAll.map(\.id), viaQuery.map(\.id))
    }

    func testFetchMatchingSupportsCustomPredicate() async throws {
        try await repository.save(JournalEntry(question: "about swift", answer: "a language"))
        try await repository.save(JournalEntry(question: "about rust", answer: "another language"))

        let predicate = #Predicate<JournalEntry> { $0.question.contains("swift") }
        let query = JournalQuery(predicate: predicate)
        let results = try await repository.fetch(matching: query)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.question, "about swift")
    }

    func testFetchMatchingSupportsCustomSortOrder() async throws {
        let first = JournalEntry(question: "a", answer: "1", createdAt: Date(timeIntervalSince1970: 0))
        let second = JournalEntry(question: "b", answer: "2", createdAt: Date(timeIntervalSince1970: 1000))
        try await repository.save(first)
        try await repository.save(second)

        let ascending = JournalQuery(sortBy: [SortDescriptor(\JournalEntry.createdAt, order: .forward)])
        let results = try await repository.fetch(matching: ascending)

        XCTAssertEqual(results.map(\.question), ["a", "b"])
    }
}
