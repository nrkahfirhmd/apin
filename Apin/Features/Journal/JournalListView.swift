// JournalListView.swift
// Apin
//
// Journal list screen (T9): reverse-chronological list of journal entries, grouped by day,
// backed live by `@Query` against ApinCore's `JournalEntry` SwiftData model (so the list stays
// current as entries are added, with no manual re-fetch). Rows navigate (via
// `NavigationLink(value:)`/`.navigationDestination(for:)`) to `JournalEntryDetailView` (T11).
//
// T10 adds keyword (`.searchable`) and date-range filtering on top of T9's list. `@Query`
// itself can't have its predicate mutated in place, so filtering works by re-deriving a
// `JournalQuery` (ApinCore's predicate/sort container) from `searchText`/`dateRange` state and
// handing it to `JournalEntryListContent`, whose `init` builds a fresh `@Query` from it —
// SwiftUI re-runs that init (and the live query) whenever the parent's state changes.
//
// T11 adds a tag filter the same way, with one twist: `JournalQuery.tagFilter` can't be folded
// into `@Query`'s `filter:` predicate either (see that property's doc comment — a real Core
// Data SQL-store limitation on `JournalEntry.tags`' storage shape, not specific to
// `SwiftDataJournalRepository`'s own fetch path). `JournalEntryListContent` applies it the same
// way `SwiftDataJournalRepository.fetch(matching:)` does: via `JournalQuery.applyTagFilter(to:)`
// on the array `@Query` already fetched/sorted/keyword-and-date-filtered, so both call sites
// share the exact same filtering rule and can't drift.
//
// See tasks/task-graph.md T9, T10, T11.

import ApinCore
import SwiftData
import SwiftUI

struct JournalListView: View {
    @State private var searchText = ""
    @State private var dateRange: ClosedRange<Date>?
    @State private var selectedTag: String?
    @State private var isDateRangeFilterPresented = false
    @State private var isTagFilterPresented = false

    var body: some View {
        // Owns its own NavigationStack for now since no root navigation composition exists
        // yet (ContentView is still T1's placeholder). Whichever task composes the app's real
        // root navigation (T7 or later) should decide whether to keep this stack or flatten it
        // into a shared one.
        NavigationStack {
            JournalEntryListContent(searchText: searchText, dateRange: dateRange, tag: selectedTag)
                .navigationTitle("Journal")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isTagFilterPresented = true
                        } label: {
                            Label(
                                "Filter by Tag",
                                systemImage: selectedTag == nil ? "tag" : "tag.fill"
                            )
                        }
                        .accessibilityIdentifier("journal.tagFilterButton")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isDateRangeFilterPresented = true
                        } label: {
                            Label(
                                "Date Range",
                                systemImage: dateRange == nil ? "calendar" : "calendar.badge.checkmark"
                            )
                        }
                        .accessibilityIdentifier("journal.dateRangeFilterButton")
                    }
                }
                .sheet(isPresented: $isDateRangeFilterPresented) {
                    JournalDateRangeFilterView(dateRange: $dateRange)
                }
                .sheet(isPresented: $isTagFilterPresented) {
                    JournalTagFilterView(selectedTag: $selectedTag)
                }
        }
        .searchable(text: $searchText, prompt: "Search question or answer")
    }
}

/// Owns the live, filtered `@Query` and renders it. Split out from `JournalListView` so a new
/// `searchText`/`dateRange`/`tag` combination (re-derived into a `JournalQuery`) can drive a
/// fresh `@Query` via `init` — see this file's header comment.
private struct JournalEntryListContent: View {
    @Query private var queriedEntries: [JournalEntry]
    private let query: JournalQuery
    private let isFiltered: Bool

    init(searchText: String, dateRange: ClosedRange<Date>?, tag: String?) {
        let query = JournalQuery.search(keyword: searchText, dateRange: dateRange, tag: tag)
        self.query = query
        _queriedEntries = Query(filter: query.predicate, sort: query.sortBy)
        isFiltered = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || dateRange != nil
            || tag != nil
    }

    /// `queriedEntries` narrowed by `query.tagFilter` — see this file's header comment and
    /// `JournalQuery.tagFilter`'s doc comment for why this can't be part of `@Query`'s own
    /// `filter:` predicate.
    private var entries: [JournalEntry] {
        query.applyTagFilter(to: queriedEntries)
    }

    var body: some View {
        if entries.isEmpty {
            JournalEmptyStateView(isFiltered: isFiltered)
        } else {
            List {
                ForEach(JournalDaySection.grouped(entries)) { section in
                    Section(section.title) {
                        ForEach(section.entries) { entry in
                            NavigationLink(value: entry) {
                                JournalEntryRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: JournalEntry.self) { entry in
                JournalEntryDetailView(entry: entry)
            }
        }
    }
}

#Preview {
    JournalListView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
