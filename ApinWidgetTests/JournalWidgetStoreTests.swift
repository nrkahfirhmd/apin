// JournalWidgetStoreTests.swift
// ApinWidgetTests
//
// Unit tests for `JournalWidgetStore` (T16).

import XCTest

final class JournalWidgetStoreTests: XCTestCase {
    func test_appGroupIdentifier_matchesConfiguredEntitlement() {
        // Keep in sync with `com.apple.security.application-groups` in both targets'
        // entitlements (see `project.yml`).
        XCTAssertEqual(JournalWidgetStore.appGroupIdentifier, "group.com.apin.app")
    }

    func test_makeModelContainer_neverCrashes() {
        // This test target has no App Group entitlement of its own configured in
        // `project.yml`. On a real device that would make `containerURL(
        // forSecurityApplicationGroupIdentifier:)` return `nil`, and `makeModelContainer()`
        // is documented to fall back to `nil` there rather than force-try/crash. On the
        // iOS Simulator, though, App Group container resolution isn't strictly gated by
        // code-signing entitlements the way it is on-device (observed empirically while
        // writing this test: it resolved successfully here despite no entitlement on this
        // target) -- so this test intentionally doesn't assert nil-vs-non-nil either way,
        // only that the call completes without crashing. See `JournalWidgetStore.
        // makeModelContainer()`'s doc comment for the on-device contract this stands in for.
        _ = JournalWidgetStore.makeModelContainer()
    }
}
