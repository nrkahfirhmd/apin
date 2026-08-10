// JournalEntryDetailView.swift
// Apin
//
// Detail screen for a single journal entry (T11): full question, full answer, a formatted
// timestamp, and a placeholder area for tag display. Reached from `JournalListView`'s
// `NavigationLink(value: entry)` rows via the `.navigationDestination(for: JournalEntry.self)`
// modifier this view is registered against.
//
// Read-only for this cycle: no editing/deletion UI. Tag editing is T20's job, built on top
// of `JournalEntry.tags` (currently always empty — nothing in the app writes tags yet), so
// the tags section here only needs to render harmlessly when empty and not crash/look broken
// if a future task populates tags.
//
// See tasks/task-graph.md T11.

import ApinCore
import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.question)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(Self.formattedTimestamp(entry.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Text(entry.answer)
                    .font(.body)

                Divider()

                tagsSection
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Placeholder tag-display area (T20 builds real tag editing/rendering here). Renders
    /// nothing when `tags` is empty — which is always, this cycle — rather than showing an
    /// empty "Tags" section header with dead space beneath it.
    @ViewBuilder
    private var tagsSection: some View {
        if !entry.tags.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags")
                    .font(.headline)
                Text(entry.tags.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Long date + short time formatting for the detail screen's timestamp, e.g.
    /// "August 10, 2026 at 3:45 PM". Split out as a static function (rather than inlined in
    /// `body`) so it's independently unit-testable — mirrors `JournalDaySection`'s pattern of
    /// keeping date logic separate from the view.
    static func formattedTimestamp(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        // `DateFormatter` doesn't infer locale/time zone from `calendar` — set them explicitly
        // so passing a fixed `calendar` (e.g. in tests) produces deterministic output.
        formatter.locale = calendar.locale ?? .current
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        JournalEntryDetailView(
            entry: JournalEntry(
                question: "What is spaced repetition?",
                answer: "A learning technique that spaces out review sessions over increasing "
                    + "intervals, timed to counteract the forgetting curve.",
                createdAt: .now
            )
        )
    }
}

#Preview("With tags") {
    NavigationStack {
        JournalEntryDetailView(
            entry: JournalEntry(
                question: "What is spaced repetition?",
                answer: "A learning technique that spaces out review sessions over increasing intervals.",
                createdAt: .now,
                tags: ["learning", "memory"]
            )
        )
    }
}
