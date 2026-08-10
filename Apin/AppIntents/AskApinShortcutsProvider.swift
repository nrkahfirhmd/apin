// AskApinShortcutsProvider.swift
// Apin
//
// T13 — registers `ApinCore`'s `AskApinIntent` as an App Shortcut so it's
// discoverable via Spotlight search and invocable via Siri without the user having
// run it before.
//
// Lives in the `Apin` app target rather than `ApinCore/Sources/AppIntents`
// (where `AskApinIntent` itself lives) for a load-bearing reason, not style
// preference: `AppIntent`'s protocol declaration carries
// `@_alwaysEmitConformanceMetadata` (see this SDK's AppIntents.swiftmodule
// `*.swiftinterface`), which is what lets `appintentsmetadataprocessor` discover
// `AskApinIntent` across the `ApinCore` -> `Apin` module boundary at all —
// `AppShortcutsProvider` does not carry that attribute. Verified empirically: with
// this type defined in `ApinCore` instead, `xcodebuild`'s
// `appintentsnltrainingprocessor` build step logged "No AppShortcuts found -
// Skipping." even though `AskApinIntent` itself was extracted correctly
// (`Metadata.appintents/extract.actionsdata` had a populated `actions.AskApinIntent`
// entry but an empty `autoShortcuts` array). Moving only this provider type here
// (the intent itself stays in `ApinCore`, matching every other App Intents type
// this task's scope names) fixed it — confirmed via the same
// `Metadata.appintents/extract.actionsdata` inspection, this time non-empty. See
// this task's completion notes in tasks/task-graph.md for the full verification
// method.
//
// See tasks/task-graph.md T13.

import AppIntents
import ApinCore

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AskApinShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskApinIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask a question in \(.applicationName)"
            ],
            shortTitle: "Ask Apin",
            systemImageName: "questionmark.bubble"
        )
    }
}
