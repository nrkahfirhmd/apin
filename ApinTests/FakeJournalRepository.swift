// FakeJournalRepository.swift
// ApinTests
//
// Fake `JournalRepository` (T6) conformance used by `AskAndSaveServiceTests` (T8)
// so "success saves once, failure saves nothing" can be unit-tested without a real
// SwiftData `ModelContainer`. Only implements what T8's tests exercise (`save`) —
// the rest of the protocol's default/fetch/delete surface is unused here and left
// as no-op/empty stubs so this type stays trivially conformant.
//
// See tasks/task-graph.md T8.

import ApinCore
import Foundation

@available(macOS 14, *)
@MainActor
final class FakeJournalRepository: JournalRepository {
    private(set) var savedEntries: [JournalEntry] = []
    var saveError: Error?

    func save(_ entry: JournalEntry) async throws {
        if let saveError {
            throw saveError
        }
        savedEntries.append(entry)
    }

    func fetch(by id: UUID) async throws -> JournalEntry? {
        savedEntries.first { $0.id == id }
    }

    func fetch(matching _: JournalQuery) async throws -> [JournalEntry] {
        savedEntries
    }

    func delete(id: UUID) async throws {
        savedEntries.removeAll { $0.id == id }
    }
}
