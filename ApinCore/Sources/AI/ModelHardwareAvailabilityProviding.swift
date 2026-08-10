// ModelHardwareAvailabilityProviding.swift
// ApinCore
//
// See tasks/task-graph.md T2.
//
// This is the only file in the capability-gate seam that imports FoundationModels
// — everything else (CapabilityGate, CapabilityGateResult, ModelHardwareAvailability)
// is framework-independent so it can be unit-tested without live device support.

import FoundationModels

/// Something that reports the current device/OS/Apple-Intelligence-toggle
/// eligibility for on-device Foundation Models inference, expressed as
/// ``ModelHardwareAvailability`` rather than the raw `FoundationModels` type.
///
/// Abstracted so ``CapabilityGate`` can be unit-tested for the `unsupportedDevice`,
/// `appleIntelligenceDisabled`, and `modelNotReady` branches with a fake, with no
/// dependency on Apple Intelligence–eligible hardware.
public protocol ModelHardwareAvailabilityProviding: Sendable {
    var modelHardwareAvailability: ModelHardwareAvailability { get }
}

/// The production ``ModelHardwareAvailabilityProviding`` implementation, backed by
/// `SystemLanguageModel.availability` — Apple's own runtime source of truth for
/// hardware eligibility, the Apple Intelligence toggle, and model readiness.
///
/// Per the plan's guidance: Apple's device-eligibility list (e.g. iPhone 15 Pro and
/// iPhone 16 or later) is not a clean chip-generation rule, so this deliberately
/// does not hardcode a device/chip allowlist — it defers entirely to Apple's API.
@available(iOS 26.0, macOS 26.0, *)
public struct DefaultModelHardwareAvailabilityProvider: ModelHardwareAvailabilityProviding {
    public init() {}

    public var modelHardwareAvailability: ModelHardwareAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .deviceNotEligible
            case .appleIntelligenceNotEnabled:
                return .appleIntelligenceNotEnabled
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                // Future-proofing: FoundationModels may add unavailable reasons in
                // a later OS release. Treat unknown reasons as a hardware/
                // eligibility gap rather than crashing on a non-exhaustive switch.
                return .deviceNotEligible
            }
        }
    }
}
