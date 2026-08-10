// PortableExportWriterTests.swift
// ApinCoreTests
//
// Unit tests for T12: `PortableExportWriter` (Markdown + JSON mirror on save). Every test
// writes into a per-test temp directory (never the real Documents path) and removes it in
// `tearDownWithError`.

import XCTest
import SwiftData
@testable import ApinCore

@available(macOS 14, *)
final class PortableExportWriterTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PortableExportWriterTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory, FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    private func makeSnapshot(
        id: UUID = UUID(),
        question: String = "What is 2+2?",
        answer: String = "4",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        tags: [String] = []
    ) -> JournalEntryExportSnapshot {
        JournalEntryExportSnapshot(id: id, question: question, answer: answer, createdAt: createdAt, tags: tags)
    }

    // MARK: - File output

    func testWriteProducesExactlyOneMarkdownAndOneJSONFileNamedByID() async throws {
        let writer = PortableExportWriter(directory: tempDirectory)
        let snapshot = makeSnapshot()

        await writer.write(snapshot)

        let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(contents.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: writer.markdownURL(for: snapshot.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: writer.jsonURL(for: snapshot.id).path))
        XCTAssertEqual(writer.markdownURL(for: snapshot.id).lastPathComponent, "\(snapshot.id.uuidString).md")
        XCTAssertEqual(writer.jsonURL(for: snapshot.id).lastPathComponent, "\(snapshot.id.uuidString).json")
    }

    func testWriteCreatesTargetDirectoryIfMissing() async throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))
        let writer = PortableExportWriter(directory: tempDirectory)

        await writer.write(makeSnapshot())

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testWriteOverwritesExistingFilesForSameID() async throws {
        let writer = PortableExportWriter(directory: tempDirectory)
        let id = UUID()

        await writer.write(makeSnapshot(id: id, question: "first", answer: "1"))
        await writer.write(makeSnapshot(id: id, question: "second", answer: "2"))

        let markdown = try String(contentsOf: writer.markdownURL(for: id), encoding: .utf8)
        XCTAssertTrue(markdown.contains("second"))
        XCTAssertFalse(markdown.contains("first"))
        let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(contents.count, 2)
    }

    // MARK: - Markdown structure/content

    func testMarkdownIncludesQuestionAsHeadingAndAnswerAsBody() {
        let snapshot = makeSnapshot(question: "Why is the sky blue?", answer: "Rayleigh scattering.")

        let markdown = PortableExportWriter.markdown(for: snapshot)

        XCTAssertTrue(markdown.contains("# Why is the sky blue?"))
        XCTAssertTrue(markdown.contains("Rayleigh scattering."))
    }

    func testMarkdownIncludesIDAndTags() {
        let id = UUID()
        let snapshot = makeSnapshot(id: id, tags: ["math", "algebra"])

        let markdown = PortableExportWriter.markdown(for: snapshot)

        XCTAssertTrue(markdown.contains(id.uuidString))
        XCTAssertTrue(markdown.contains("math, algebra"))
    }

    func testMarkdownRendersEmptyTagsHarmlessly() {
        let snapshot = makeSnapshot(tags: [])

        let markdown = PortableExportWriter.markdown(for: snapshot)

        XCTAssertFalse(markdown.isEmpty)
        XCTAssertTrue(markdown.contains("tags:"))
    }

    // MARK: - JSON schema/content

    func testJSONIncludesSchemaVersion() throws {
        let snapshot = makeSnapshot()

        let data = try PortableExportWriter.jsonData(for: snapshot)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(object?["schemaVersion"] as? Int, JournalEntryExportSnapshot.currentSchemaVersion)
    }

    func testJSONRoundTripsAllFields() throws {
        let snapshot = makeSnapshot(
            id: UUID(),
            question: "Q?",
            answer: "A.",
            createdAt: Date(timeIntervalSince1970: 1_234_567),
            tags: ["one", "two"]
        )

        let data = try PortableExportWriter.jsonData(for: snapshot)
        let decoded = try JSONDecoder(dateStrategy: .iso8601).decode(JournalEntryExportSnapshot.self, from: data)

        XCTAssertEqual(decoded, snapshot)
    }

    // MARK: - Repository integration (the save hook)

    @MainActor
    func testSavingEntryViaRepositoryWritesMarkdownAndJSONMirror() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let writer = PortableExportWriter(directory: tempDirectory)
        let repository = SwiftDataJournalRepository(modelContainer: container, saveSideEffects: [writer])
        let entry = JournalEntry(question: "Repo hook question", answer: "Repo hook answer")

        try await repository.save(entry)

        XCTAssertTrue(FileManager.default.fileExists(atPath: writer.markdownURL(for: entry.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: writer.jsonURL(for: entry.id).path))
        let markdown = try String(contentsOf: writer.markdownURL(for: entry.id), encoding: .utf8)
        XCTAssertTrue(markdown.contains("Repo hook question"))
        XCTAssertTrue(markdown.contains("Repo hook answer"))
    }

    // Deliberately not tested against `PortableExportWriter.defaultDirectory`/the real
    // Documents path: per T12's acceptance criteria, tests must not touch the real
    // filesystem. `testSavingEntryViaRepositoryWritesMarkdownAndJSONMirror` above already
    // covers the `save()` -> side-effect wiring with an injected temp-directory writer; the
    // default-argument wiring (`saveSideEffects: [JournalEntrySaveSideEffect] =
    // [PortableExportWriter()]` in `SwiftDataJournalRepository`'s initializers) is a one-line,
    // directly-readable default and isn't separately exercised on disk here.

    @MainActor
    func testEmptySideEffectsArrayResultsInNoFilesWritten() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: configuration)
        let repository = SwiftDataJournalRepository(modelContainer: container, saveSideEffects: [])
        let entry = JournalEntry(question: "No side effects", answer: "Nothing written")

        try await repository.save(entry)

        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))
    }
}

private extension JSONDecoder {
    convenience init(dateStrategy: JSONDecoder.DateDecodingStrategy) {
        self.init()
        self.dateDecodingStrategy = dateStrategy
    }
}
