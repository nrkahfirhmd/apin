// CapabilityGateDebugOverrideTests.swift
// ApinCoreTests
//
// Unit tests for T3's `#if DEBUG`-gated capability-gate override. Runs only in
// Debug test builds (the type under test doesn't exist in Release — see that
// file's header), which matches how `swift test`/Xcode's default test action
// build, so these run in CI/local test passes without any special config.
//
// See tasks/task-graph.md T3.

#if DEBUG
import XCTest
@testable import ApinCore

final class CapabilityGateDebugOverrideTests: XCTestCase {
    func testForcedResultMapsEachRecognizedEnvironmentValue() {
        let cases: [(String, CapabilityGateResult)] = [
            ("available", .available),
            ("unsupportedDevice", .unsupportedDevice),
            ("unsupportedOS", .unsupportedOS),
            ("appleIntelligenceDisabled", .appleIntelligenceDisabled),
            ("modelNotReady", .modelNotReady)
        ]

        for (value, expected) in cases {
            let environment = [CapabilityGateDebugOverride.environmentVariableName: value]

            XCTAssertEqual(
                CapabilityGateDebugOverride.forcedResult(from: environment),
                expected,
                "Expected \(value) to map to \(expected)"
            )
        }
    }

    func testForcedResultIsNilWhenEnvironmentVariableIsUnset() {
        XCTAssertNil(CapabilityGateDebugOverride.forcedResult(from: [:]))
    }

    func testForcedResultIsNilWhenEnvironmentVariableIsUnrecognized() {
        let environment = [CapabilityGateDebugOverride.environmentVariableName: "not-a-real-case"]

        XCTAssertNil(CapabilityGateDebugOverride.forcedResult(from: environment))
    }

    func testGateReturnsNilWhenNoOverrideIsSet() {
        XCTAssertNil(CapabilityGateDebugOverride.gate(environment: [:]))
    }

    func testGateReturnsAGatingConformanceThatAlwaysReturnsTheForcedResult() {
        let environment = [CapabilityGateDebugOverride.environmentVariableName: "unsupportedOS"]

        let gate = CapabilityGateDebugOverride.gate(environment: environment)

        XCTAssertEqual(gate?.checkCapability(), .unsupportedOS)
        // Calling repeatedly should keep returning the same forced result — this
        // is a fixed override, not a one-shot value.
        XCTAssertEqual(gate?.checkCapability(), .unsupportedOS)
    }
}
#endif
