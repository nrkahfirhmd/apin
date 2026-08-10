// ApinWidgetProvider.swift
// ApinWidget
//
// WidgetKit `TimelineProvider` for the recent-entry widget (T16). Reads the most recent
// `JournalEntry` via `JournalWidgetStore`'s shared-container `ModelContainer` and never
// throws/crashes -- an unreachable store or an empty journal both resolve to
// `ApinWidgetEntry.empty`, which `ApinWidgetEntryView` renders as a sensible empty state.
//
// Reload policy: `.after(nextReloadDate)` on a fixed 1-hour interval
// (`reloadInterval`). WidgetKit budgets a limited number of reloads per day, and nothing
// in this cycle pushes a reload on save (that would need a `WidgetCenter.shared.
// reloadTimelines` call from the app/journal-save path, which is outside this task's
// `ApinWidget/`-only scope). An hourly cap keeps the widget's relative "asked 12m
// ago"-style timestamp from going stale indefinitely without over-spending the reload
// budget. Revisit if a save-triggered reload becomes worth wiring in (e.g. alongside
// T17's quick-ask entry point).

import ApinCore
import SwiftData
import WidgetKit

struct ApinWidgetProvider: TimelineProvider {
    static let reloadInterval: TimeInterval = 60 * 60

    func placeholder(in context: Context) -> ApinWidgetEntry {
        .placeholder
    }

    // Synchronous, not `Task`/`@MainActor`-hopping -- see `JournalWidgetStore.
    // makeModelContainer()`'s doc comment for why: these completion handlers are
    // non-`Sendable` closures under Swift 6 strict concurrency, so the fetch runs and
    // calls back within the same execution context it was given.
    func getSnapshot(in context: Context, completion: @escaping (ApinWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : Self.fetchLatestEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ApinWidgetEntry>) -> Void) {
        let entry = Self.fetchLatestEntry()
        let nextReload = Date().addingTimeInterval(Self.reloadInterval)
        completion(Timeline(entries: [entry], policy: .after(nextReload)))
    }

    /// Fetches the single most recent `JournalEntry` from the shared store. Returns
    /// `.empty` (never throws/crashes) when the shared container isn't reachable or the
    /// journal has no entries yet -- both are legitimate, expected states for a widget
    /// extension process, not error conditions.
    private static func fetchLatestEntry() -> ApinWidgetEntry {
        guard let container = JournalWidgetStore.makeModelContainer() else {
            return .empty
        }

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let latest = try? context.fetch(descriptor).first
        return ApinWidgetEntry.make(from: latest)
    }
}
