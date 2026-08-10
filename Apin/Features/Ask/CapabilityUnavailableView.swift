// CapabilityUnavailableView.swift
// Apin
//
// T3 — the standalone screen shown whenever T2's capability gate returns
// anything other than `.available`. Does NOT implement the Ask screen itself
// (that's T7, which composes this view in alongside the capability gate check).
// See tasks/task-graph.md T3 and planning/engineering-plan.md item #3 (Req 7).

import ApinCore
import SwiftUI

/// Renders a clear, non-crashing explanation for every non-`.available`
/// ``CapabilityGateResult``, distinguishing hard "unsupported hardware/OS" cases
/// (including `.modelNotReady`, a temporary "still downloading" state) from the
/// user-fixable `.appleIntelligenceDisabled` case.
///
/// A single view branching its copy on the case, per T3's acceptance criteria —
/// callers (T7, and later T17's widget quick-ask entry point) pass in whatever
/// ``CapabilityGateResult`` the gate produced.
struct CapabilityUnavailableView: View {
    let result: CapabilityGateResult

    /// Injectable so this stays testable in a preview/host view without needing
    /// UIKit's real Settings deep link to fire.
    var openSettings: () -> Void = {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    private var copy: CapabilityStatusCopy {
        CapabilityStatusCopyProvider.copy(for: result)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(copy.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(copy.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionHint = copy.actionHint {
                if copy.isUserActionable {
                    Button(actionHint, action: openSettings)
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                } else {
                    Text(actionHint)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch result {
        case .available:
            return "checkmark.circle"
        case .unsupportedOS, .unsupportedDevice:
            return "exclamationmark.triangle"
        case .appleIntelligenceDisabled:
            return "gearshape"
        case .modelNotReady:
            return "arrow.down.circle"
        }
    }
}

#Preview("Unsupported OS") {
    CapabilityUnavailableView(result: .unsupportedOS)
}

#Preview("Unsupported Device") {
    CapabilityUnavailableView(result: .unsupportedDevice)
}

#Preview("Apple Intelligence Disabled") {
    CapabilityUnavailableView(result: .appleIntelligenceDisabled)
}

#Preview("Model Not Ready") {
    CapabilityUnavailableView(result: .modelNotReady)
}

#Preview("Available") {
    CapabilityUnavailableView(result: .available)
}
