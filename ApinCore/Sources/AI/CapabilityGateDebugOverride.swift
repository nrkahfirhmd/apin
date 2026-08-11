// CapabilityGateDebugOverride.swift
// ApinCore
//
// T3 — a `#if DEBUG`-gated escape hatch that lets a launch-environment variable
// force any of the 5 `CapabilityGateResult` cases, bypassing `CapabilityGate`'s
// real OS-version/hardware/Apple-Intelligence-toggle checks. Exists purely so
// `/qa` and manual testers can render `Apin/Features/Ask/CapabilityUnavailableView.swift`
// and drive `AskView`'s unsupported branch end-to-end in Simulator, without needing
// a real disqualifying device — see `memory/technical-debt.md`'s "Unsupported-
// device/OS path only structurally verified, never manually exercised" entry.
//
// `#if DEBUG`-gated deliberately, not just "unused in production": a capability
// gate is a safety-relevant check (Req 7 — never claim on-device inference is
// available when it isn't), so it must be structurally impossible — not merely
// unwired — for a Release build to have any code path that lets an environment
// variable fake availability. Wrapping the entire type (not just its call site)
// in `#if DEBUG` means the symbol doesn't exist in a Release build at all: there
// is no `CapabilityGateDebugOverride` for anything to reference, so
// `AskViewModel.live`'s Release path unconditionally falls through to
// `CapabilityGate.live()` (see that file's `resolvedCapabilityGate()`). This is
// verifiable by building with `-configuration Release` — the build succeeds only
// because the Release-path call site never mentions this type outside its own
// `#if DEBUG` block; deleting this file's `#if DEBUG` guard while leaving
// `AskViewModel`'s guard in place would still compile fine in Debug, but a true
// regression (removing the guard from *both* files) would make this type ship in
// Release, which `/review` should treat as a Req 7 safety regression if ever seen.
//
// See tasks/task-graph.md T3 and planning/engineering-plan.md item #3 (Req 7).

#if DEBUG
import Foundation

/// Reads `APIN_DEBUG_CAPABILITY_OVERRIDE` from the process environment (set via
/// the Xcode scheme's "Arguments > Environment Variables", or `xcodebuild test`'s
/// `-env`) and, if it names one of the 5 `CapabilityGateResult` cases, hands back
/// a `CapabilityGating` conformance that always returns that forced result.
///
/// Only compiled into Debug builds — see this file's header for why that's a hard
/// requirement, not a convenience.
public enum CapabilityGateDebugOverride {
    /// The launch-environment variable name this override reads. Recognized
    /// values are the `CapabilityGateResult` case names exactly as written:
    /// `available`, `unsupportedDevice`, `unsupportedOS`,
    /// `appleIntelligenceDisabled`, `modelNotReady`. Any other value (including
    /// unset) is treated as "no override" — see ``gate()``.
    public static let environmentVariableName = "APIN_DEBUG_CAPABILITY_OVERRIDE"

    /// Builds the forced `CapabilityGating` conformance from the current process
    /// environment, or `nil` if `environmentVariableName` is unset or doesn't
    /// match a recognized case — callers should fall back to the real
    /// `CapabilityGate.live()` in that case (see `AskViewModel.live`).
    public static func gate(environment: [String: String] = ProcessInfo.processInfo.environment) -> CapabilityGating? {
        guard let result = forcedResult(from: environment) else { return nil }
        return ForcedCapabilityGate(result: result)
    }

    /// Parses `environment[environmentVariableName]` into a `CapabilityGateResult`.
    /// Exposed separately from ``gate()`` so tests can assert the string-to-case
    /// mapping without going through `ProcessInfo` or constructing a
    /// `CapabilityGating` conformance.
    static func forcedResult(from environment: [String: String]) -> CapabilityGateResult? {
        switch environment[environmentVariableName] {
        case "available":
            return .available
        case "unsupportedDevice":
            return .unsupportedDevice
        case "unsupportedOS":
            return .unsupportedOS
        case "appleIntelligenceDisabled":
            return .appleIntelligenceDisabled
        case "modelNotReady":
            return .modelNotReady
        default:
            return nil
        }
    }
}

/// Trivial `CapabilityGating` conformance that always returns a fixed result,
/// regardless of the real device's OS/hardware/Apple Intelligence state.
/// `CapabilityGateDebugOverride.gate()` is the only intended way to construct
/// one — kept `internal` (not `public`) so nothing outside this override
/// mechanism can quietly depend on "a gate that always returns X" in production
/// code.
struct ForcedCapabilityGate: CapabilityGating {
    let result: CapabilityGateResult

    func checkCapability() -> CapabilityGateResult {
        result
    }
}
#endif
