// ApinAppModelConfigurationTests.swift
// ApinTests
//
// Regression pin for `ApinApp`'s shared App Group store location (T18). Mirrors
// `ApinWidgetTests.JournalWidgetStoreTests.test_appGroupIdentifier_matchesConfiguredEntitlement`
// on the widget side — `ApinTests` and `ApinWidgetTests` are separate test targets with no
// dependency between them, so this is intentionally a second, independent pin on the same
// literal values rather than a single shared assertion. If either pin changes without the
// other, the app and widget targets silently stop sharing a store again (see
// `Apin/ApinApp.swift`'s doc comment on these constants).
//
// Deliberately does NOT call `ApinApp.makeModelConfiguration()` here: that method
// `fatalError`s if the App Group container can't be resolved, which would crash this whole
// test target in any environment where the App Group entitlement doesn't resolve (this test
// target has no App Group entitlement of its own in `project.yml`, mirroring the widget
// test target's equivalent, documented constraint).

import XCTest

@testable import Apin

final class ApinAppModelConfigurationTests: XCTestCase {
    func test_appGroupIdentifier_matchesWidgetSideValue() {
        // Keep in sync with `ApinWidget/JournalWidgetStore.appGroupIdentifier` and the
        // `com.apple.security.application-groups` entitlement on both targets (project.yml).
        XCTAssertEqual(ApinApp.appGroupIdentifier, "group.com.apin.app")
    }

    func test_storeFileName_matchesWidgetSideValue() {
        // Keep in sync with `ApinWidget/JournalWidgetStore.storeFileName`.
        XCTAssertEqual(ApinApp.storeFileName, "ApinJournal.sqlite")
    }
}
