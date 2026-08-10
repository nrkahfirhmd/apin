// FakeJournalSearchIndexing.swift
// ApinCoreTests
//
// Fake `JournalSearchIndexing` conformance used by `JournalSearchIndexerTests` (T14) so
// indexing-payload construction and the save/delete hook wiring can be unit-tested without a
// live on-device Spotlight index.

import Foundation
@testable import ApinCore

final class FakeJournalSearchIndexing: JournalSearchIndexing, @unchecked Sendable {
    private(set) var indexedPayloads: [JournalSearchIndexPayload] = []
    private(set) var deletedIDs: [UUID] = []

    func index(_ payload: JournalSearchIndexPayload) async {
        indexedPayloads.append(payload)
    }

    func deleteIndexedItem(id: UUID) async {
        deletedIDs.append(id)
    }
}
