// AskApinIntent.swift
// ApinCore
//
// T13 — the Spotlight/Siri deep-link entry point. Scope is deliberately narrow per
// tasks/task-graph.md: open the app, hand the typed query to `AskDeepLinkCoordinator`
// (which `Apin/Features/Ask/AskView.swift` consumes into `AskViewModel.prefill(with:)`),
// and let T7/T8's existing Ask screen + auto-save flow do the rest. This intent does
// NOT call the assistant model or the journal repository itself — no ask/save logic
// is duplicated here (per T8's header, that flow's canonical entry point stays
// `AskViewModel.submit()` -> `AskAndSaveServicing`), and it makes zero network
// requests of its own.
//
// `supportedModes = .foreground(.immediate)` is the current (iOS 26) replacement for
// the deprecated `openAppWhenRun = true` — verified against this SDK's
// AppIntents.swiftmodule/*.swiftinterface (`AppIntent.openAppWhenRun` carries
// `@available(iOS, deprecated: 26.0, message: "Please provide 'supportedModes'
// instead")`). `.foreground(.immediate)` always brings the app to the foreground and
// runs `perform()` in-process (see `AskDeepLinkCoordinator`'s header for why that
// matters), matching the old `openAppWhenRun = true` behavior this task wants.
//
// T15 (separate, explicitly optional task) may later add an inline no-app-open
// answer path; this intent's `perform()` stays deliberately simple (navigate +
// prefill only) so that work stays additive rather than requiring a rewrite here.
//
// See tasks/task-graph.md T13, T8, T7.

import AppIntents

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public struct AskApinIntent: AppIntent {
    public static let title: LocalizedStringResource = "Ask Apin"

    public static let description = IntentDescription(
        "Ask Apin a question. Opens the app with your question ready to send.",
        categoryName: "Ask"
    )

    /// Always opens/foregrounds the app and runs `perform()` in-process — this
    /// intent has no inline (no-app-open) answer path (that's T15's separate,
    /// explicitly optional spike).
    public static let supportedModes: IntentModes = .foreground(.immediate)

    /// Discoverable via Spotlight search/App Shortcuts without requiring the user to
    /// have run it before.
    public static let isDiscoverable: Bool = true

    @Parameter(title: "Question", description: "What you want to ask Apin.")
    public var query: String

    public static var parameterSummary: some ParameterSummary {
        Summary("Ask Apin \(\.$query)")
    }

    public init() {
        self.query = ""
    }

    public init(query: String) {
        self.query = query
    }

    /// Deliberately simple: hands `query` to `AskDeepLinkCoordinator` for `AskView`
    /// to pick up and does nothing else. No model call, no journal write, no
    /// network request — those all happen inside the app via the existing T7/T8 Ask
    /// flow once the user submits from the (now-prefilled) Ask screen.
    @MainActor
    public func perform() async throws -> some IntentResult {
        AskDeepLinkCoordinator.shared.requestAsk(query: query)
        return .result()
    }
}
