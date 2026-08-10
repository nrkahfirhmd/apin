// AskDeepLinkCoordinator.swift
// ApinCore
//
// T13 — the mailbox `AskApinIntent.perform()` uses to hand a typed query into the
// already-running (or freshly-launched) app process. `AskApinIntent` runs inside the
// `Apin` app's own process (see `AskApinIntent`'s `supportedModes` — `.foreground`
// intents execute in-process, not in a separate extension process), so a plain
// process-wide singleton is sufficient here; no IPC/Darwin-notification/App Group
// plumbing is needed the way `ApinWidget`'s cross-process reads are (see
// `ApinWidget/JournalWidgetStore.swift`).
//
// `Apin/Features/Ask/AskView.swift` observes `shared.pendingQuery` (it's
// `@Observable`, so SwiftUI's view-body tracking picks up changes automatically)
// and, when a query appears, consumes it and hands it to `AskViewModel.prefill(with:)`
// — the exact seam `AskViewModel`'s header already documents T13 using. This type
// deliberately knows nothing about `AskViewModel`/SwiftUI (`ApinCore` must not import
// either) — it's just a typed one-slot mailbox.
//
// `@MainActor` because `AskApinIntent.perform()` and `AskView`'s SwiftUI code both
// read/write it from the main actor; isolating the whole type avoids needing
// `await`/locks for what is otherwise a single stored property.
//
// See tasks/task-graph.md T13.

import Observation

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
@Observable
public final class AskDeepLinkCoordinator {
    /// Process-wide singleton — `AskApinIntent` and `AskView` both need to reach the
    /// exact same instance, and there is exactly one of these per app process.
    public static let shared = AskDeepLinkCoordinator()

    /// The most recently requested deep-link query, if any hasn't been consumed yet.
    /// `AskView` is expected to consume this (via ``consumePendingQuery()``) as soon
    /// as it observes a non-`nil` value, so this should not accumulate stale state.
    public private(set) var pendingQuery: String?

    /// Not `private` (unlike a strict singleton) so tests can construct isolated
    /// instances instead of sharing the mutable `shared` process-wide singleton
    /// across test cases. Production call sites should use `.shared`.
    public init() {}

    /// Called by `AskApinIntent.perform()` with the user's typed query.
    public func requestAsk(query: String) {
        pendingQuery = query
    }

    /// Called by `AskView` once it has observed a pending query and is about to hand
    /// it to `AskViewModel.prefill(with:)`. Clears the slot so the same query isn't
    /// re-applied on a later, unrelated view update.
    @discardableResult
    public func consumePendingQuery() -> String? {
        defer { pendingQuery = nil }
        return pendingQuery
    }
}
