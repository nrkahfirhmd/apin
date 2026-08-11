# T3 — Manual Simulator Verification of All 5 `CapabilityGateResult` Cases

Performed as part of the T3 rework requested by `/review` (Cycle 2, 2026-08-11 — see
`review/review-report.md`'s "Gaps found" #2 and `tasks/task-graph.md`'s T3 Notes). The
`#if DEBUG` override mechanism itself (`ApinCore/Sources/AI/CapabilityGateDebugOverride.swift`,
`Apin/Features/Ask/AskViewModel.swift`'s `resolvedCapabilityGate()`) was already independently
verified correct and absent from Release by `/review`'s own `nm`/`strings` check — this pass only
performs the second, previously-undocumented half of T3's acceptance criteria: actually rendering
all 5 `CapabilityGateResult` cases end-to-end in Simulator and confirming non-crashing, correct UI.

## Environment

- Date: 2026-08-11
- Host: macOS 26.5.2 (build 25F84), Xcode 26.6 (build 17F113)
- Simulator: iPhone 17, iOS 26.3 (runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-3`),
  device UDID `70435877-CA84-4EDB-A54D-DF15CB5764A3` (already booted at time of test)
- Build: `xcodebuild -project Apin.xcodeproj -scheme Apin -configuration Debug -destination
  'id=70435877-CA84-4EDB-A54D-DF15CB5764A3' build` — **BUILD SUCCEEDED**
- App installed via `xcrun simctl install`, bundle id `com.apin.app`
- Each case launched via:
  `SIMCTL_CHILD_APIN_DEBUG_CAPABILITY_OVERRIDE=<case> xcrun simctl launch <udid> com.apin.app`
  (the `SIMCTL_CHILD_` prefix is `simctl`'s documented mechanism for passing an environment
  variable through to the launched child process — confirmed to reach
  `CapabilityGateDebugOverride.gate()` via `ProcessInfo.processInfo.environment`, since
  `resolvedCapabilityGate()` is only reachable in Debug builds and this Debug build exercised it).
- Screenshot taken via `xcrun simctl io <udid> screenshot <path>` immediately after each launch;
  app terminated (`xcrun simctl terminate`) between cases so each launch is a clean cold start.

## Method

For each of the 5 `CapabilityGateResult` cases, launched the app with
`APIN_DEBUG_CAPABILITY_OVERRIDE` set to the case's exact raw value (per
`CapabilityGateDebugOverride.forcedResult(from:)`'s `switch`), captured a screenshot of `AskView`'s
resulting state, and cross-checked the rendered title/message/action-hint copy against
`CapabilityStatusCopyProvider.copy(for:)` (`Apin/Features/Ask/CapabilityUnavailableCopy.swift`) and
`ApinTests/CapabilityStatusCopyProviderTests.swift`'s expectations. Confirmed via `xcrun simctl
spawn <udid> log show` (filtered to `process == "Apin"`) that no crash/fatalError/exception log
lines appear around each launch, and via `~/Library/Logs/DiagnosticReports` that no new `.ips`
crash report was generated for this simulator during the test window (09:46 local).

## Results

| Case | Screenshot | Observed | Matches expected copy | Crash? |
|---|---|---|---|---|
| `available` | `available.png` | Normal `AskView` ask flow rendered (text field, "Ask" button, idle "Ask Apin Something" empty state, digest toolbar button) — `.available` skips `CapabilityUnavailableView` entirely, per `AskView.body`'s `if viewModel.capability == .available` branch. | Yes — this is the expected non-`CapabilityUnavailableView` path. | No |
| `unsupportedDevice` | `unsupportedDevice.png` | `CapabilityUnavailableView` rendered: warning-triangle icon, title "Device Not Supported", body "This device's hardware doesn't support Apple Intelligence, so Apin's on-device intelligence can't run here. This isn't something a setting can change — it requires newer hardware.", no action button/hint. | Yes, exact match to `CapabilityStatusCopyProvider`'s `.unsupportedDevice` case (`actionHint: nil`). | No |
| `unsupportedOS` | `unsupportedOS.png` | `CapabilityUnavailableView` rendered: warning-triangle icon, title "Update Required", body "Apin's on-device intelligence needs a newer version of iOS than this device is currently running. Update iOS to use this feature.", plain (non-button) footnote hint "Update iOS in Settings > General > Software Update." | Yes, exact match; hint correctly rendered as plain text (not a button), consistent with `isUserActionable == false`. | No |
| `appleIntelligenceDisabled` | `appleIntelligenceDisabled.png` | `CapabilityUnavailableView` rendered: gear icon, title "Apple Intelligence Is Off", body "This device supports Apple Intelligence, but it's currently turned off. Turn it on in Settings to use Apin.", blue tappable button "Open Settings > Apple Intelligence & Siri to turn it on." | Yes, exact match; hint correctly rendered as a `.borderedProminent` button, consistent with `isUserActionable == true` (the only case that is). | No |
| `modelNotReady` | `modelNotReady.png` | `CapabilityUnavailableView` rendered: down-arrow-circle icon, title "Getting Ready", body "Apple Intelligence is on, but the on-device model is still downloading or preparing. This usually finishes on its own — try again in a little while.", plain footnote hint "No action needed — check back shortly." | Yes, exact match; hint correctly rendered as plain text, consistent with `isUserActionable == false`. | No |

All 5 icons (`checkmark.circle` implicitly for `.available` via the normal ask flow rather than
`CapabilityUnavailableView`, `exclamationmark.triangle` for both unsupported cases, `gearshape` for
`appleIntelligenceDisabled`, `arrow.down.circle` for `modelNotReady`) match
`CapabilityUnavailableView.symbolName`'s switch exactly.

**No crashes, hangs, or fatal errors observed for any of the 5 cases.** Each launch produced a
foregrounded, fully-rendered `AskView` (confirmed via screenshot) and a clean `simctl launch`
return (a PID, no error) with no corresponding crash-report `.ips` file generated for this
simulator during the test window.

## Evidence files

- `available.png`, `unsupportedDevice.png`, `unsupportedOS.png`, `appleIntelligenceDisabled.png`,
  `modelNotReady.png` — one screenshot per case, this directory.
- This `README.md`.

## Conclusion

T3's remaining acceptance-criteria gap — "All 5 `CapabilityGateResult` cases have been manually
rendered end-to-end in Simulator and each is confirmed to show correct, non-crashing UI —
documented in completion notes" — is satisfied and durably recorded here. See
`memory/technical-debt.md`'s "Unsupported-device/OS path only structurally verified, never
manually exercised" entry, updated to `resolved` pointing at this file.
