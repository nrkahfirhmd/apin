// CoreSpotlightIndexAdapter.swift
// ApinCore
//
// Production conformance of `JournalSearchIndexing` that wraps Apple's `CSSearchableIndex`
// from the `CoreSpotlight` framework. This is the only file in the Persistence module that
// talks to the real framework's index/item types directly — `JournalSearchIndexer` (the
// `JournalEntrySaveSideEffect`/`JournalEntryDeleteSideEffect` conformance) is written
// entirely against the `JournalSearchIndexing` seam so it can be exercised with a fake in
// tests. See tasks/task-graph.md T14.
//
// API-shape note: CoreSpotlight is an Objective-C framework with no `.swiftinterface` in the
// SDK, so the exact async surface was verified directly against the iOS 26 SDK's
// `CSSearchableIndex.h`/`CSSearchableItem.h`/`CSSearchableItemAttributeSet*.h` headers (the
// same technique T2/T4 used for FoundationModels) and confirmed with a `swiftc -typecheck`
// probe. `indexSearchableItems(_:completionHandler:)` and
// `deleteSearchableItems(withIdentifiers:completionHandler:)` both take a plain
// `(NSError? -> Void)` completion handler with no `NS_SWIFT_NAME`/`NS_SWIFT_ASYNC_NAME`
// override, so the Swift compiler bridges them automatically to `async throws` overloads
// that drop the completion handler — no manual `withCheckedThrowingContinuation` wrapping
// needed here.
//
// This file must never import SwiftUI/UIKit. CoreSpotlight itself is not a UI framework.

import Foundation

#if canImport(CoreSpotlight)
import CoreSpotlight
import UniformTypeIdentifiers

/// Wraps a real `CSSearchableIndex` (by default, `CSSearchableIndex.default()`, the app's
/// default on-device Spotlight index).
///
/// The macOS 14 floor below (higher than CoreSpotlight's own macOS 11/iOS 14
/// `init(contentType:)` minimum) only matters for `swift build`/`swift test` run directly on
/// a macOS host — see `JournalEntry.swift`'s comment for why this package's other
/// Persistence types share the same floor; the package's declared iOS 26 platform minimum
/// already exceeds it for real app/widget builds.
@available(macOS 14, *)
public final class CoreSpotlightIndexAdapter: JournalSearchIndexing, @unchecked Sendable {
    /// Domain identifier shared by every journal entry's searchable item, so a future
    /// bulk-delete (e.g. "remove all Apin journal entries from Spotlight") could target it
    /// via `deleteSearchableItems(withDomainIdentifiers:)`. Not used this cycle — manual
    /// single-entry delete is the only deletion path in scope (T6's retention policy).
    public static let domainIdentifier = "com.apin.journalEntry"

    // `CSSearchableIndex` isn't `Sendable` in the SDK's annotations, but its documented
    // contract is safe to call from any queue/task; `@unchecked Sendable` on this wrapper
    // records that as a deliberate, reviewed exception, matching
    // `FoundationModelsSessionAdapter`'s treatment of `LanguageModelSession`.
    private let index: CSSearchableIndex

    /// - Parameter index: Injectable for testing/alternate index instances; defaults to
    ///   `CSSearchableIndex.default()`.
    public init(index: CSSearchableIndex = .default()) {
        self.index = index
    }

    // MARK: - JournalSearchIndexing

    public func index(_ payload: JournalSearchIndexPayload) async {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = payload.question
        attributeSet.contentDescription = payload.answer
        attributeSet.contentCreationDate = payload.createdAt

        let item = CSSearchableItem(
            uniqueIdentifier: payload.id.uuidString,
            domainIdentifier: Self.domainIdentifier,
            attributeSet: attributeSet
        )
        // Journal entries are kept forever by default (T6's retention policy: no automatic
        // archiving/deletion) — CSSearchableItem defaults to a 1-month expiration, so reset
        // it here to avoid entries silently dropping out of Spotlight search over time.
        item.expirationDate = .distantFuture

        do {
            try await index.indexSearchableItems([item])
        } catch {
            #if DEBUG
            print("CoreSpotlightIndexAdapter: failed to index entry \(payload.id): \(error)")
            #endif
        }
    }

    public func deleteIndexedItem(id: UUID) async {
        do {
            try await index.deleteSearchableItems(withIdentifiers: [id.uuidString])
        } catch {
            #if DEBUG
            print("CoreSpotlightIndexAdapter: failed to delete indexed entry \(id): \(error)")
            #endif
        }
    }
}
#endif
