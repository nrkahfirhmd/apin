// ApinWidget.swift
// ApinWidget
//
// WidgetKit configuration for Apin's recent-entry widget (T16): shows the most recent
// journal entry's question and an answer snippet, via `ApinWidgetProvider` /
// `ApinWidgetEntryView`. T17 added a quick-ask `Button(intent:)` on top of this same
// configuration -- see `ApinWidgetEntryView`'s header for the intent-reuse decision.
// See tasks/task-graph.md T16, T17.

import SwiftUI
import WidgetKit

struct ApinWidget: Widget {
    let kind: String = "ApinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ApinWidgetProvider()) { entry in
            ApinWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Apin")
        .description("Shows your most recent question and answer from Apin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
