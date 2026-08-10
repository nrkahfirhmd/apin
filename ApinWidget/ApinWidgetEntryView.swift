// ApinWidgetEntryView.swift
// ApinWidget
//
// Renders an `ApinWidgetEntry`: the most recent question/answer snippet, or a sensible
// empty state (T16 acceptance criteria) when `hasEntry` is false.
//
// T17 -- adds the widget's quick-ask entry point: a `Button(intent:)` overlaid on both
// states. This extension deliberately does NOT construct its own `AskViewModel`/
// `AssistantSessionService`/`JournalRepository` -- it only triggers `AskApinIntent`
// (T13), which runs in the *app's* process (see that intent's `supportedModes`) and
// hands the query to `AskDeepLinkCoordinator` for `AskView` to consume via the exact
// same T7/T8 ask-and-save flow a manual tap would use. No ask/save logic is duplicated
// here, and this interaction makes zero network requests of its own -- it only opens
// the app.
//
// Intent-reuse decision: reuses `AskApinIntent` (constructed as `AskApinIntent()`,
// i.e. `query: ""`) rather than adding a second `OpenAskScreenIntent`. This is safe
// end to end, not just "happens to compile":
//   - `AskApinIntent(query:)` sets `query` directly on the intent value the button
//     hands to WidgetKit -- unlike a Siri/Spotlight invocation, there is no parameter
//     disambiguation prompt for a directly-constructed intent instance, even with an
//     empty string.
//   - `AskDeepLinkCoordinator.requestAsk(query:)` stores it as `pendingQuery = ""`
//     (a non-nil, but empty, `String`), which `AskView.applyPendingDeepLinkQueryIfNeeded()`
//     still picks up (it only checks for `nil`) and forwards to `AskViewModel.prefill(with:)`.
//   - `AskView` then unconditionally calls `viewModel.submit()`, but `AskViewModel.submit()`
//     itself no-ops when `canSubmit` is `false` (`!trimmedQuery.isEmpty && !isBusy` --
//     see `AskViewModel.swift`), so an empty prefill never fires a request. Net effect:
//     the app opens straight to a blank, ready-to-type Ask screen -- exactly the
//     "quick-ask" UX this task wants -- with zero new types and zero duplicated
//     prefill/submit wiring.
// A second minimal intent was considered (per this task's notes) but rejected as
// unnecessary complexity once the empty-string path above was verified safe.

import AppIntents
import ApinCore
import SwiftUI
import WidgetKit

struct ApinWidgetEntryView: View {
    let entry: ApinWidgetEntry

    var body: some View {
        Group {
            if entry.hasEntry {
                recentEntryView
            } else {
                emptyStateView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .overlay(alignment: .topTrailing) {
            quickAskButton
        }
    }

    /// T17's quick-ask entry point. Deep-link only -- see the file header for why
    /// reusing `AskApinIntent()` (empty query) is safe and duplicates nothing.
    private var quickAskButton: some View {
        Button(intent: AskApinIntent()) {
            Image(systemName: "plus.bubble.fill")
                .font(.caption)
                .padding(6)
        }
        .buttonStyle(.plain)
        .background(.thinMaterial, in: Circle())
        .padding(8)
        .accessibilityLabel("Ask Apin a question")
    }

    private var recentEntryView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Apin", systemImage: "sparkles")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.question)
                .font(.headline)
                .lineLimit(2)

            Text(entry.answerSnippet)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)

            if let createdAt = entry.createdAt {
                Text(createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No entries yet")
                .font(.subheadline.weight(.semibold))
            Text("Answers you ask Apin will show up here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemSmall) {
    ApinWidget()
} timeline: {
    ApinWidgetEntry.placeholder
    ApinWidgetEntry.empty
}
