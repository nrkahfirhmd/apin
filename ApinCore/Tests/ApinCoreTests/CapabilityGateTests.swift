// CapabilityGateTests.swift
// ApinCoreTests
//
// Unit tests for T2's capability gate. Uses fakes for OS version and
// `SystemLanguageModel.availability` (via ``ModelHardwareAvailability``) so these
// pass with no live device dependency. See tasks/task-graph.md T2.

import XCTest
@testable import ApinCore

private struct FakeOSVersionProvider: OSVersionProviding {
    var isRunningSupportedOSVersion: Bool
}

private struct FakeModelHardwareAvailabilityProvider: ModelHardwareAvailabilityProviding {
    var modelHardwareAvailability: ModelHardwareAvailability
}

final class CapabilityGateTests: XCTestCase {
    private func makeGate(
        isRunningSupportedOSVersion: Bool,
        modelHardwareAvailability: ModelHardwareAvailability
    ) -> CapabilityGate {
        CapabilityGate(
            osVersionProvider: FakeOSVersionProvider(
                isRunningSupportedOSVersion: isRunningSupportedOSVersion
            ),
            modelHardwareAvailabilityProvider: FakeModelHardwareAvailabilityProvider(
                modelHardwareAvailability: modelHardwareAvailability
            )
        )
    }

    func testAvailableWhenOSSupportedAndModelAvailable() {
        let gate = makeGate(isRunningSupportedOSVersion: true, modelHardwareAvailability: .available)

        XCTAssertEqual(gate.checkCapability(), .available)
    }

    func testUnsupportedOSWhenOSVersionIsTooOld() {
        // Model availability shouldn't matter once the OS check fails — the gate
        // should short-circuit to `.unsupportedOS` regardless of hardware state.
        let gate = makeGate(isRunningSupportedOSVersion: false, modelHardwareAvailability: .available)

        XCTAssertEqual(gate.checkCapability(), .unsupportedOS)
    }

    func testUnsupportedDeviceWhenHardwareIsNotEligible() {
        let gate = makeGate(isRunningSupportedOSVersion: true, modelHardwareAvailability: .deviceNotEligible)

        XCTAssertEqual(gate.checkCapability(), .unsupportedDevice)
    }

    func testAppleIntelligenceDisabledWhenToggleIsOff() {
        let gate = makeGate(
            isRunningSupportedOSVersion: true,
            modelHardwareAvailability: .appleIntelligenceNotEnabled
        )

        XCTAssertEqual(gate.checkCapability(), .appleIntelligenceDisabled)
    }

    func testModelNotReadyWhenAssetsAreStillPreparing() {
        let gate = makeGate(isRunningSupportedOSVersion: true, modelHardwareAvailability: .modelNotReady)

        XCTAssertEqual(gate.checkCapability(), .modelNotReady)
    }

    /// Confirms `CapabilityGate.live()` actually compiles and wires up to the real
    /// `FoundationModels` availability without crashing. Does not assert a specific
    /// result — the live device's actual capability state is not something this
    /// test controls (and shouldn't need Apple Intelligence–eligible hardware to
    /// pass), it only proves the production seam is wired correctly.
    @available(iOS 26.0, macOS 26.0, *)
    func testLiveGateDoesNotCrash() {
        let gate = CapabilityGate.live()

        _ = gate.checkCapability()
    }

    func testDefaultOSVersionProviderReflectsCurrentRuntime() {
        // On the CI/dev machine this test runs on (iOS 26+/macOS 26+ per the
        // package's minimum), this should be true; guards against accidentally
        // inverting the `#available` check.
        if #available(iOS 26.0, macOS 26.0, *) {
            XCTAssertTrue(DefaultOSVersionProvider().isRunningSupportedOSVersion)
        } else {
            XCTAssertFalse(DefaultOSVersionProvider().isRunningSupportedOSVersion)
        }
    }
}
