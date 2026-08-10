// CapabilityStatusCopyProviderTests.swift
// ApinTests
//
// Structural coverage for T3's `CapabilityStatusCopyProvider` (`Apin/Features/Ask/
// CapabilityUnavailableCopy.swift`): every `CapabilityGateResult` case must produce non-empty,
// mutually distinct title/message copy, and `isUserActionable` must be `true` only for the one
// case a user can actually fix themselves (`.appleIntelligenceDisabled`).
//
// Added as part of T19's polish pass, which explicitly must not regress
// `CapabilityUnavailableView`'s five already-shipped cases — this test existed only in the
// task's assumed baseline, not the actual repo, so it's added here rather than skipped. Copy
// production code (`CapabilityUnavailableCopy.swift`) is untouched by T19; this test only
// guards it. See tasks/task-graph.md T3, T19.

import ApinCore
import XCTest
@testable import Apin

final class CapabilityStatusCopyProviderTests: XCTestCase {
    private static let allCases: [CapabilityGateResult] = [
        .available,
        .unsupportedOS,
        .unsupportedDevice,
        .appleIntelligenceDisabled,
        .modelNotReady
    ]

    func testEveryCaseProducesNonEmptyTitleAndMessage() {
        for result in Self.allCases {
            let copy = CapabilityStatusCopyProvider.copy(for: result)
            XCTAssertFalse(copy.title.isEmpty, "Expected non-empty title for \(result)")
            XCTAssertFalse(copy.message.isEmpty, "Expected non-empty message for \(result)")
        }
    }

    func testEveryCaseProducesDistinctTitles() {
        let titles = Self.allCases.map { CapabilityStatusCopyProvider.copy(for: $0).title }
        XCTAssertEqual(Set(titles).count, titles.count, "Expected all 5 titles to be distinct, got \(titles)")
    }

    func testEveryCaseProducesDistinctMessages() {
        let messages = Self.allCases.map { CapabilityStatusCopyProvider.copy(for: $0).message }
        XCTAssertEqual(Set(messages).count, messages.count, "Expected all 5 messages to be distinct, got \(messages)")
    }

    func testOnlyAppleIntelligenceDisabledIsUserActionable() {
        for result in Self.allCases {
            let copy = CapabilityStatusCopyProvider.copy(for: result)
            let expected = (result == .appleIntelligenceDisabled)
            XCTAssertEqual(
                copy.isUserActionable,
                expected,
                "Expected isUserActionable == \(expected) for \(result), got \(copy.isUserActionable)"
            )
        }
    }

    /// `.unsupportedOS`/`.unsupportedDevice` are never `isUserActionable` (no Settings toggle
    /// fixes them) — `.unsupportedOS` still carries a non-nil `actionHint` (e.g. "update iOS"),
    /// but `CapabilityUnavailableView` renders it as plain informational text, not a tappable
    /// button, precisely because `isUserActionable` is `false`. Only `isUserActionable` (not
    /// `actionHint` presence) decides button-vs-text.
    func testUnsupportedHardwareAndOSCasesAreNotUserActionable() {
        for result: CapabilityGateResult in [.unsupportedOS, .unsupportedDevice] {
            let copy = CapabilityStatusCopyProvider.copy(for: result)
            XCTAssertFalse(copy.isUserActionable, "\(result) is not something a Settings toggle can fix")
        }
    }

    func testUnsupportedDeviceOffersNoActionHint() {
        let copy = CapabilityStatusCopyProvider.copy(for: .unsupportedDevice)
        XCTAssertNil(copy.actionHint, "Hardware limitation has nothing actionable to hint at")
    }

    func testAppleIntelligenceDisabledOffersAnActionHint() {
        let copy = CapabilityStatusCopyProvider.copy(for: .appleIntelligenceDisabled)
        XCTAssertNotNil(copy.actionHint)
        XCTAssertTrue(copy.isUserActionable)
    }
}
