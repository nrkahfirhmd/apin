// PortableExportWriter.swift
// ApinCore
//
// Mirrors every saved `JournalEntry` as a Markdown file and a JSON file on disk, so the
// journal is portable/human-readable outside the app (e.g. via Files/iCloud Drive) even
// though no importer/reader exists yet. See tasks/task-graph.md T12.
//
// This file must never import SwiftUI/UIKit.

import Foundation

/// `JournalEntrySaveSideEffect` conformance that writes a Markdown + JSON mirror of each
/// saved entry into `directory` (by default, `Documents/Apin/Journal/`).
///
/// Export-only: this cycle does not build any import/read-back UI (see the spec's
/// non-goals) — the files written here have no reader yet other than a human via Files/
/// iCloud Drive, or a future Mac companion app.
@available(macOS 14, *)
public struct PortableExportWriter: JournalEntrySaveSideEffect {
    public let directory: URL
    // `FileManager` isn't `Sendable` in the SDK's annotations, but per Apple's documentation
    // the methods used here on the default/injected instance are safe to call from multiple
    // threads/tasks; `nonisolated(unsafe)` records that as a deliberate, reviewed exception
    // rather than silently disabling `Sendable` checking for the whole type.
    private nonisolated(unsafe) let fileManager: FileManager

    /// - Parameters:
    ///   - directory: Where to write the `.md`/`.json` mirror files. Defaults to
    ///     `defaultDirectory`. Tests inject a temp directory here instead of writing to the
    ///     real Documents path.
    ///   - fileManager: Injectable for testing; defaults to `.default`.
    public init(directory: URL = PortableExportWriter.defaultDirectory, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// `Documents/Apin/Journal/` inside the app's Documents directory — the
    /// app-group/iCloud-Drive-visible location called for by the spec (Req 8). Wiring the
    /// app target's actual app-group container URL in (if/when one is configured) is a
    /// one-line change at this call site, not a change to `PortableExportWriter` itself.
    public static var defaultDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent("Apin/Journal", isDirectory: true)
    }

    // MARK: - JournalEntrySaveSideEffect

    @MainActor
    public func journalEntryDidSave(_ entry: JournalEntry) async {
        // Snapshot the `Sendable` fields we need while still on the caller's (main) actor —
        // `entry` itself is a SwiftData model and must not cross off-actor.
        let snapshot = JournalEntryExportSnapshot(entry: entry)
        await write(snapshot)
    }

    // MARK: - Writing

    /// Writes both the Markdown and JSON mirror of `snapshot` into `directory`, named/keyed
    /// by `snapshot.id`. Exposed directly (not just through `journalEntryDidSave(_:)`) so
    /// this can be unit-tested against a temp directory using a plain `Sendable` snapshot
    /// value, independent of SwiftData/the main actor.
    ///
    /// Marked `@concurrent` so this (potentially blocking) file I/O runs off the main actor
    /// rather than inheriting the caller's (main actor) isolation, which is the default for
    /// `nonisolated async` functions as of Swift 6.2 (SE-0461).
    ///
    /// Failures are logged and swallowed, never thrown: SwiftData is the source of truth for
    /// journal entries, and this export is a best-effort convenience mirror on top of it — a
    /// failed write here must not fail or roll back the actual journal save. See
    /// `JournalEntrySaveSideEffect`'s doc comment for the contract this relies on.
    @concurrent
    public func write(_ snapshot: JournalEntryExportSnapshot) async {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let markdown = Self.markdown(for: snapshot)
            try markdown.write(to: markdownURL(for: snapshot.id), atomically: true, encoding: .utf8)
            let json = try Self.jsonData(for: snapshot)
            try json.write(to: jsonURL(for: snapshot.id), options: .atomic)
        } catch {
            #if DEBUG
            print("PortableExportWriter: failed to write export for entry \(snapshot.id): \(error)")
            #endif
        }
    }

    public func markdownURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).md")
    }

    public func jsonURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    // MARK: - Formatting

    /// The Markdown representation of a journal entry: the question as the heading, the
    /// answer as the body, and a small metadata footer (id/timestamp/tags).
    public static func markdown(for snapshot: JournalEntryExportSnapshot) -> String {
        let timestamp = ISO8601DateFormatter().string(from: snapshot.createdAt)
        let tagsLine = snapshot.tags.isEmpty ? "_none_" : snapshot.tags.joined(separator: ", ")
        return """
        # \(snapshot.question)

        \(snapshot.answer)

        ---
        - id: \(snapshot.id.uuidString)
        - createdAt: \(timestamp)
        - tags: \(tagsLine)
        """
    }

    /// The JSON representation of a journal entry. See `JournalEntryExportSnapshot` for the
    /// schema, including the `schemaVersion` field.
    public static func jsonData(for snapshot: JournalEntryExportSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }
}
