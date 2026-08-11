// ApinApp.swift
// Apin
//
// App entry point. Root view composition (capability-gate routing from T2/T3, the Ask
// screen from T7) is still wired in by later tasks — `ContentView` remains a placeholder.
//
// T9 adds the `.modelContainer(for: JournalEntry.self)` scene modifier below: `@Query`
// (used by T9's `JournalListView`) needs a `ModelContainer` in the SwiftUI environment to
// resolve against, and nothing configured one yet.
//
// T8 needs the same `ModelContainer` instance outside the SwiftUI environment too (to build
// a `JournalRepository` for `AskView`'s auto-save flow), so this now owns the container
// explicitly (via the `modelContainer(_:)` overload that takes an already-built instance)
// instead of the `for:` convenience overload that builds and hides one internally.
//
// T18: the store now lives in the shared App Group container (see
// `appGroupIdentifier`/`storeFileName` below) instead of this target's own private
// Application Support directory, and syncs via CloudKit (`cloudKitDatabase: .automatic`).
// Both changes live on the same `ModelConfiguration` — SwiftData only allows one
// configuration per store, so "where the store lives" and "whether it syncs" have to be
// decided together here. See `makeModelConfiguration()` below for details and
// `ApinWidget/JournalWidgetStore.swift` for the widget-side counterpart this mirrors.

import ApinCore
import SwiftData
import SwiftUI

@main
struct ApinApp: App {
    /// App Group identifier and shared store filename, mirrored exactly from
    /// `ApinWidget/JournalWidgetStore.appGroupIdentifier`/`storeFileName` so the `Apin` app
    /// and `ApinWidgetExtension` targets read/write the exact same on-disk SwiftData store.
    /// Duplicated (not imported) because the widget extension and app are separate compiled
    /// targets with no dependency between them — both depend on `ApinCore`, but neither of
    /// these constants lives there today. If you change either value here, change it in
    /// `JournalWidgetStore.swift` too, or the widget silently goes back to reading an empty
    /// store. Internal (not `private`) so `ApinTests.ApinAppModelConfigurationTests` can pin
    /// these literals against `ApinWidgetTests.JournalWidgetStoreTests`' equivalent
    /// assertions, mirroring that test's pattern — `ApinTests` and `ApinWidgetTests` are
    /// separate targets with no shared dependency, so this can only be enforced as two
    /// independent regression pins on the same literal values, not a single shared constant.
    static let appGroupIdentifier = "group.com.apin.app"
    static let storeFileName = "ApinJournal.sqlite"

    /// Shared across the SwiftUI environment (for `@Query`, e.g. T9's journal list) and
    /// `ContentView`'s explicit `JournalRepository` construction (for T8's auto-save).
    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: JournalEntry.self, configurations: Self.makeModelConfiguration())
        } catch {
            fatalError("Failed to create ModelContainer for JournalEntry: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
                .task {
                    deduplicateJournalEntriesAtLaunch()
                }
        }
        .modelContainer(modelContainer)
    }

    /// Startup dedup pass for `JournalEntry` rows sharing an `id` — see
    /// `SwiftDataJournalRepository.deduplicateEntries()`'s doc comment and
    /// `memory/technical-debt.md`, "No DB-level uniqueness guarantee on `JournalEntry.id`
    /// post-CloudKit" (T1). Runs once per launch, after the root view appears (`.task` timing),
    /// since this is a defensive cleanup for entries that could only have diverged before T1's
    /// `fetch(by:)`/`delete(id:)` fix landed — not a path any normal launch is expected to
    /// exercise. Failure is logged, not fatal: an un-deduplicated store is still fully usable.
    private func deduplicateJournalEntriesAtLaunch() {
        do {
            let removedCount = try SwiftDataJournalRepository(modelContainer: modelContainer).deduplicateEntries()
            if removedCount > 0 {
                print("Apin: removed \(removedCount) duplicate JournalEntry row(s) sharing an id at launch.")
            }
        } catch {
            print("Apin: journal entry dedup pass failed at launch: \(error)")
        }
    }

    /// Builds the CloudKit-backed `ModelConfiguration` for the journal store, pointed at the
    /// shared App Group container so `ApinWidgetExtension` can read the same data (T16/T18).
    ///
    /// Fails fast (`fatalError`, via the `ModelContainer` construction above) if the App
    /// Group container isn't reachable. Unlike the widget's `JournalWidgetStore
    /// .makeModelContainer()`, which treats a missing container as "fall back to an empty
    /// timeline", the main app has no reasonable degraded mode here — every screen depends
    /// on a working `ModelContainer` being in the environment. A missing App Group container
    /// means the entitlement/provisioning is broken and needs fixing, not working around.
    ///
    /// CloudKit note: `cloudKitDatabase: .automatic` mirrors this store to the signed-in
    /// user's private CloudKit database using the app's default container
    /// (`iCloud.com.apin.app`, see the `com.apple.developer.icloud-container-identifiers`
    /// entitlement in `project.yml`). Conflict resolution across devices is handled by
    /// SwiftData/Core Data's CloudKit mirroring delegate, which is last-writer-wins at the
    /// *field* level per synced record (not whole-object): if the same `JournalEntry` is
    /// edited concurrently on two devices, the merged record ends up with each field taken
    /// from whichever write CloudKit's server considers most recent, not necessarily all
    /// fields from a single device's edit. This is documented Apple behavior, not something
    /// this app customizes.
    private static func makeModelConfiguration() -> ModelConfiguration {
        guard let groupContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError(
                "App Group container '\(appGroupIdentifier)' is not reachable. Check the "
                    + "com.apple.security.application-groups entitlement (project.yml) and, on a "
                    + "real device, that this App Group is registered for the app's provisioning profile."
            )
        }

        let storeURL = groupContainerURL.appendingPathComponent(storeFileName)
        return ModelConfiguration(url: storeURL, cloudKitDatabase: .automatic)
    }
}
