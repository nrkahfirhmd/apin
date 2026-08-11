// JournalTagFilterView.swift
// Apin
//
// Tag-filter picker sheet for T11's journal search, mirroring `JournalDateRangeFilterView`'s
// shape (a sheet that commits back via a binding on "Apply"/tap, with a "Clear Filter" action
// when a filter is already active). Presented from `JournalListView`'s toolbar.
//
// Lists every distinct tag currently attached to any journal entry (via its own `@Query`, so it
// stays live as entries/tags change) rather than accepting free-typed text — tag filtering is an
// exact match (see `JournalQuery.tagFilter`'s doc comment), so picking from what already exists
// avoids the user typing a tag that can never match anything.
//
// See tasks/task-graph.md T11.

import ApinCore
import SwiftData
import SwiftUI

struct JournalTagFilterView: View {
    @Binding var selectedTag: String?
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]

    private var availableTags: [String] {
        Set(allEntries.flatMap(\.tags)).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableTags.isEmpty {
                    ContentUnavailableView(
                        "No Tags Yet",
                        systemImage: "tag",
                        description: Text("Add tags to journal entries to filter by them here.")
                    )
                } else {
                    List(availableTags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                            dismiss()
                        } label: {
                            HStack {
                                Text(tag)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if tag == selectedTag {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter by Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedTag != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Clear Filter", role: .destructive) {
                            selectedTag = nil
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    JournalTagFilterView(selectedTag: .constant(nil))
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
