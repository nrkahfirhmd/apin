// CapabilityUnavailableCopy.swift
// Apin
//
// Copy-provider ("view model") for T3's unsupported-device/OS UX screen. Maps
// every ``CapabilityGateResult`` case (T2) to display copy, kept as a plain,
// SwiftUI-free function so it's testable in isolation from rendering. See
// tasks/task-graph.md T3 and planning/engineering-plan.md item #3 (Req 7).
//
// This lives in the Apin app target (not ApinCore) because it's presentation
// copy for a single screen, not shared business logic — ApinCore stays free of
// anything UI-adjacent per T1's module boundary rule.

import ApinCore

/// Display copy for one capability-gate state: a title, a body explanation, and
/// an optional action hint (e.g. "Open Settings to turn on Apple Intelligence").
struct CapabilityStatusCopy: Equatable, Sendable {
    let title: String
    let message: String
    let actionHint: String?

    /// Whether `actionHint`, if present, describes something the user can
    /// actually do right now (vs. just informational context like "this will
    /// resolve on its own"). Drives whether the view renders the hint as a
    /// tappable action or as plain text.
    let isUserActionable: Bool
}

/// Maps ``CapabilityGateResult`` to ``CapabilityStatusCopy``.
///
/// Every non-`.available` case must produce copy that meaningfully distinguishes
/// "this device/OS can't run it, ever" (`.unsupportedOS`, `.unsupportedDevice`)
/// from "the model is still getting ready, this resolves on its own"
/// (`.modelNotReady`) from "Apple Intelligence is off, you can fix this"
/// (`.appleIntelligenceDisabled`).
enum CapabilityStatusCopyProvider {
    static func copy(for result: CapabilityGateResult) -> CapabilityStatusCopy {
        switch result {
        case .available:
            return CapabilityStatusCopy(
                title: "Apin Is Ready",
                message: "On-device intelligence is available on this device right now.",
                actionHint: nil,
                isUserActionable: false
            )

        case .unsupportedOS:
            return CapabilityStatusCopy(
                title: "Update Required",
                message: "Apin's on-device intelligence needs a newer version of iOS than " +
                    "this device is currently running. Update iOS to use this feature.",
                actionHint: "Update iOS in Settings > General > Software Update.",
                isUserActionable: false
            )

        case .unsupportedDevice:
            return CapabilityStatusCopy(
                title: "Device Not Supported",
                message: "This device's hardware doesn't support Apple Intelligence, so " +
                    "Apin's on-device intelligence can't run here. This isn't something a " +
                    "setting can change — it requires newer hardware.",
                actionHint: nil,
                isUserActionable: false
            )

        case .appleIntelligenceDisabled:
            return CapabilityStatusCopy(
                title: "Apple Intelligence Is Off",
                message: "This device supports Apple Intelligence, but it's currently turned " +
                    "off. Turn it on in Settings to use Apin.",
                actionHint: "Open Settings > Apple Intelligence & Siri to turn it on.",
                isUserActionable: true
            )

        case .modelNotReady:
            return CapabilityStatusCopy(
                title: "Getting Ready",
                message: "Apple Intelligence is on, but the on-device model is still " +
                    "downloading or preparing. This usually finishes on its own — try again " +
                    "in a little while.",
                actionHint: "No action needed — check back shortly.",
                isUserActionable: false
            )
        }
    }
}
