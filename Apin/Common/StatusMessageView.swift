// StatusMessageView.swift
// Apin
//
// T19 — small, shared empty/error status view reused across the Ask screen's idle/error
// states and the Journal list's "no entries yet" empty state, so those states look and feel
// visually consistent (icon + title + message via `ContentUnavailableView`). This is a thin,
// opinionated convenience wrapper, not a replacement for `ContentUnavailableView` itself —
// Journal search's "no results" state keeps using the framework's built-in `.search` variant
// directly (see `JournalEmptyStateView`), since that's already exactly the right thing.
//
// Deliberately NOT used by `CapabilityUnavailableView` (T3): that screen's copy/action-hint
// layout (`CapabilityUnavailableCopy.swift`) is materially different per case (a tappable
// Settings button for the user-actionable case, plain informational text otherwise), and
// forcing it through this generic empty/error shape would risk regressing its five
// already-verified cases — explicitly out of scope for this polish pass. See
// tasks/task-graph.md T19 and planning/engineering-plan.md item #18 (Req 1, 4, 7).

import SwiftUI

/// A small, reusable status view: SF Symbol + title + message, rendered via
/// `ContentUnavailableView` so it inherits standard system empty-state layout/spacing.
struct StatusMessageView: View {
    /// Visual intent — drives icon tint so an error reads as distinct from a neutral empty
    /// state at a glance.
    enum Style {
        case empty
        case error
    }

    let style: Style
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(style == .error ? .red : .primary)
        } description: {
            Text(message)
        }
    }
}

#Preview("Empty") {
    StatusMessageView(
        style: .empty,
        systemImage: "bubble.left.and.text.bubble.right",
        title: "Ask Apin Something",
        message: "Type a question above to get a personalized, on-device answer."
    )
}

#Preview("Error") {
    StatusMessageView(
        style: .error,
        systemImage: "exclamationmark.triangle",
        title: "Couldn't Get an Answer",
        message: "Something went wrong. Try again."
    )
}
