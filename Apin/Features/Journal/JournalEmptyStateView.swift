// JournalEmptyStateView.swift
// Apin
//
// Empty state shown by `JournalListView` when there are no journal entries yet, or (T10) when
// a keyword/date-range search matches nothing. See tasks/task-graph.md T9, T10, T19.
//
// T19: the "no entries yet" case now renders through the shared `StatusMessageView`
// (Apin/Common), matching the Ask screen's empty state visually. The filtered/"no search
// results" case deliberately keeps using `ContentUnavailableView.search` directly rather than
// going through `StatusMessageView` — it's already exactly the right built-in system empty
// state for a search-with-no-matches, and both stay distinct/non-misleading (one never claims
// "no entries yet" when entries exist but are filtered out).

import SwiftUI

struct JournalEmptyStateView: View {
    /// `true` when a keyword/date-range filter (T10) is active and produced no matches, as
    /// opposed to the journal genuinely having no entries yet.
    var isFiltered: Bool = false

    var body: some View {
        if isFiltered {
            ContentUnavailableView.search
        } else {
            StatusMessageView(
                style: .empty,
                systemImage: "book.closed",
                title: "No Entries Yet",
                message: "Answers you ask Apin will show up here."
            )
        }
    }
}

#Preview {
    JournalEmptyStateView()
}

#Preview("Filtered") {
    JournalEmptyStateView(isFiltered: true)
}
