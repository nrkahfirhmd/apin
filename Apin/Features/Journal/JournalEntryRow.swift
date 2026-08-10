// JournalEntryRow.swift
// Apin
//
// Single-row presentation for a journal entry inside `JournalListView`'s day sections.
// See tasks/task-graph.md T9.

import ApinCore
import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.question)
                .font(.headline)
                .lineLimit(2)
            Text(entry.answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(entry.createdAt, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalEntryRow(
        entry: JournalEntry(
            question: "What is spaced repetition?",
            answer: "A learning technique that spaces out review sessions over increasing intervals.",
            createdAt: .now
        )
    )
    .padding()
}
