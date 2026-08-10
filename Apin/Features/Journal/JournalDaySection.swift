// JournalDaySection.swift
// Apin
//
// Groups journal entries by calendar day for `JournalListView`. Pure grouping logic, kept
// separate from the view so day-bucketing/section-title behavior is easy to reason about
// independently of SwiftUI. See tasks/task-graph.md T9.

import ApinCore
import Foundation

/// One calendar day's worth of journal entries, newest-first, with a display-ready section
/// title ("Today", "Yesterday", or a formatted calendar date).
struct JournalDaySection: Identifiable {
    /// Start-of-day timestamp for this section, used as a stable, sortable identity.
    let id: Date
    let title: String
    let entries: [JournalEntry]

    /// Groups `entries` into day sections, preserving newest-first ordering both across
    /// sections and within each section. Assumes `entries` is already sorted newest-first
    /// (as `@Query(sort:order:)` provides) rather than re-sorting.
    static func grouped(
        _ entries: [JournalEntry],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [JournalDaySection] {
        let startOfToday = calendar.startOfDay(for: now)
        var dayOrder: [Date] = []
        var entriesByDay: [Date: [JournalEntry]] = [:]

        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if entriesByDay[day] == nil {
                entriesByDay[day] = []
                dayOrder.append(day)
            }
            entriesByDay[day]?.append(entry)
        }

        return dayOrder.map { day in
            JournalDaySection(
                id: day,
                title: sectionTitle(for: day, startOfToday: startOfToday, calendar: calendar),
                entries: entriesByDay[day] ?? []
            )
        }
    }

    private static func sectionTitle(for day: Date, startOfToday: Date, calendar: Calendar) -> String {
        if day == startOfToday {
            return "Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday), day == yesterday {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: day)
    }
}
