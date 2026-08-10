// JournalDateRangeFilterView.swift
// Apin
//
// Date-range picker sheet for T10's journal search. Presented from `JournalListView`'s
// toolbar; edits a draft range locally and only commits it back (via the `dateRange` binding)
// when the user taps "Apply," so canceling doesn't clobber whatever filter was already active.
// See tasks/task-graph.md T10.

import SwiftUI

struct JournalDateRangeFilterView: View {
    @Binding var dateRange: ClosedRange<Date>?
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date

    init(dateRange: Binding<ClosedRange<Date>?>) {
        self._dateRange = dateRange
        let now = Date.now
        self._startDate = State(initialValue: dateRange.wrappedValue?.lowerBound ?? now)
        self._endDate = State(initialValue: dateRange.wrappedValue?.upperBound ?? now)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let lowerBound = Calendar.current.startOfDay(for: startDate)
                        let upperBound = endOfDay(for: endDate)
                        dateRange = lowerBound...upperBound
                        dismiss()
                    }
                }
                if dateRange != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Clear Filter", role: .destructive) {
                            dateRange = nil
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func endOfDay(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        return calendar.date(byAdding: .second, value: -1, to: startOfNextDay) ?? date
    }
}

#Preview {
    JournalDateRangeFilterView(dateRange: .constant(nil))
}
