// CapabilityGate.swift
// ApinCore
//
// See tasks/task-graph.md T2 and planning/engineering-plan.md item #2 (Req 7).

/// Checks OS version, hardware capability, and the Apple Intelligence toggle state
/// and returns one typed ``CapabilityGateResult``.
///
/// This is the single source of truth every entry point (Ask screen, widget, App
/// Intent) should branch on — do not let callers re-derive availability with their
/// own `if #available` or hardware checks.
///
/// Injected with ``OSVersionProviding`` and ``ModelHardwareAvailabilityProviding``
/// so it's fully unit-testable with fakes (no live device dependency). Use
/// ``live()`` to get the production instance wired to the real OS version and
/// `FoundationModels.SystemLanguageModel.availability`.
public struct CapabilityGate: CapabilityGating {
    private let osVersionProvider: OSVersionProviding
    private let modelHardwareAvailabilityProvider: ModelHardwareAvailabilityProviding

    public init(
        osVersionProvider: OSVersionProviding,
        modelHardwareAvailabilityProvider: ModelHardwareAvailabilityProviding
    ) {
        self.osVersionProvider = osVersionProvider
        self.modelHardwareAvailabilityProvider = modelHardwareAvailabilityProvider
    }

    public func checkCapability() -> CapabilityGateResult {
        guard osVersionProvider.isRunningSupportedOSVersion else {
            return .unsupportedOS
        }

        switch modelHardwareAvailabilityProvider.modelHardwareAvailability {
        case .available:
            return .available
        case .deviceNotEligible:
            return .unsupportedDevice
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceDisabled
        case .modelNotReady:
            return .modelNotReady
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension CapabilityGate {
    /// The production ``CapabilityGate``, wired to the real OS version and
    /// `FoundationModels.SystemLanguageModel.availability`.
    public static func live() -> CapabilityGate {
        CapabilityGate(
            osVersionProvider: DefaultOSVersionProvider(),
            modelHardwareAvailabilityProvider: DefaultModelHardwareAvailabilityProvider()
        )
    }
}
