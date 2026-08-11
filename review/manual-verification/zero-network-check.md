# Manual Verification — Zero Network Requests During Model Invocation

**For:** Kv, to execute on the physical device ("Kahfi's Phone," iPhone 17) — not something a
task-runner subagent can do (no tooling for interactive device/Instruments capture).

**Task:** T2 (`tasks/task-graph.md`). **Backlog item:** #2 (`planning/engineering-plan.md`).
**Closes (contingent on the result below):** `memory/technical-debt.md`'s "'Zero network
requests...' not dynamically verified" entry — recorded in T5, not by running this script itself.

This document is self-contained. You should not need to open `planning/engineering-plan.md` or
`tasks/task-graph.md` to run it.

## Why this check exists

Apin's core value proposition is that answering a question never leaves the device. This has
only ever been checked **statically**: `grep -rln "URLSession\|CFNetwork\|import Network"` across
`Apin/`, `ApinCore/`, `ApinWidget/` returns zero matches — the model-invocation path
(`ApinCore/Sources/AI/AssistantSessionService.swift` and its concrete session adapter,
`Apin/Features/Ask/AskView.swift` / `AskViewModel.swift`) imports only `Foundation` and
`FoundationModels`.

That's reassuring but not proof: a future dependency, or unexpected behavior inside an Apple
framework, would not show up in a grep. This script is the **dynamic** check that closes that
gap — it observes/blocks actual network traffic on a real device while the app answers a real
question. Treat the grep result above as supporting context only, not as a substitute for
actually running one of the two methods below.

## What you're testing

The Ask flow: opening Apin, typing a question into the "Ask Apin something…" field, tapping the
"Ask" button, and letting the on-device model (`FoundationModels`) produce and finish streaming
an answer. This is the app's only screen (no tab bar/navigation to worry about — the app opens
directly into it).

Run **either** Method A or Method B below; running both gives higher confidence but either one
alone is sufficient to pass. Do them with normal Wi-Fi/cellular connectivity available going in
(Method B intentionally disables it as part of the test — don't pre-disable it for Method A, or
you won't be able to tell "the app made zero calls" from "the app couldn't have made calls
anyway").

---

## Method A — Instruments' Network instrument (passive capture)

Confirms directly: during the Ask flow, the Apin process generates zero network connections/bytes.

### Setup

1. Connect the iPhone ("Kahfi's Phone") to your Mac via cable, or ensure it's already paired for
   wireless debugging (Xcode > Window > Devices and Simulators > confirm it's listed and trusted).
2. Make sure Apin is installed on the phone and is a Debug or Release build you can launch (either
   is fine — this check doesn't depend on build configuration).
3. On the Mac, open **Instruments** (Xcode > Open Developer Tool > Instruments, or launch
   Instruments.app directly from Applications/Xcode).
4. In the template chooser, select the **Network** template.
5. In the toolbar, next to the record button, click the target/device selector and choose
   **Kahfi's Phone** as the device.
6. In the same selector, choose **Apin** as the target process. If Apin isn't already running on
   the phone, Instruments will launch it for you when you hit record — that's fine, that's the
   "app opens directly into the Ask screen" state you want anyway.

### Capture

7. Click the red **Record** button to start the capture. Confirm on the phone that Apin is now
   open, showing the "Ask" screen (title "Ask", text field placeholder "Ask Apin something…", an
   "Ask" button below it, greyed out until you type something).
8. Tap the text field and type a representative question, e.g. **"What's a good way to start a
   daily journaling habit?"** (any ordinary question works — the point is triggering a real model
   invocation, not the content of the answer).
9. Tap the **Ask** button.
10. Wait through the full response: the "Thinking…" spinner, then the streaming partial-answer
    text, until the text stops updating (final answered state).
11. Once the answer has fully finished rendering, **keep recording for another 15 seconds**
    without touching anything else in the app — this catches any delayed/async call that might
    fire just after the visible answer completes.
12. Stop the capture (Cmd+. or the stop/record button toggled off).

### Observe

13. In Instruments' Network track/list for this recording, filter or scroll to the **Apin**
    process's entries for the full time window from step 7 (app opens) through the end of step 11
    (15s after the answer finished).
14. Look specifically at bytes-sent/bytes-received and the connection list for that window and
    that process.

### Pass / fail

- **Pass:** Zero connections and zero bytes sent/received attributed to the Apin process for the
  entire window covering app-open → question typed → "Ask" tapped → answer fully streamed → 15s
  after.
- **Fail:** Any connection or nonzero byte count attributed to the Apin process anywhere in that
  window, regardless of destination or size.
- Traffic from **other** processes (e.g. system daemons, `cloudd`, `springboard`) during the same
  window is not itself a failure of this check — this check is scoped to what the **Apin process**
  does during the Ask flow, not general device network activity. If you see something attributed
  to Apin you're unsure how to classify, treat it as a fail and note the details in the Result
  section below rather than deciding it doesn't count.

---

## Method B — Network Link Conditioner, "100% Loss" (active block)

Confirms the complementary thing: the Ask flow still **works** — produces a complete answer —
even when the device has zero network connectivity, proving the answer path has no network
dependency at all (rather than just "didn't happen to make a call this time").

### Setup

1. On the iPhone, open **Settings**. If you don't see a **Developer** section near the bottom of
   the root Settings list, connect the phone to your Mac and open it once in Xcode's Window >
   Devices and Simulators with Developer Mode enabled — the Developer section then appears in
   Settings automatically. (If you've built/run Apin from Xcode onto this phone before, it's
   already there.)
2. Go to **Settings > Developer > Network Link Conditioner**.
3. Tap **Profile** and select **100% Loss**.
4. Toggle **Network Link Conditioner** to **On**.
5. If this menu isn't present at all after step 1's check (some iOS versions require the
   "Additional Tools for Xcode" package installed on the Mac and its conditioner profile pushed to
   the device via Xcode's Devices window first), fall back to a simpler equivalent: turn on
   **Airplane Mode** on the phone (Control Center or Settings), which also fully cuts Wi-Fi and
   cellular. Note in the Result section below which of the two you used.

### Capture

6. With the network fully blocked (either method), open **Apin**. It should land directly on the
   "Ask" screen.
7. Tap the text field, type a representative question (same kind as Method A, e.g. **"What's a
   good way to start a daily journaling habit?"**).
8. Tap **Ask**.
9. Watch what happens: does it go through "Thinking…", stream a partial answer, and complete with
   a full answer, the same as it would with network on?

### Pass / fail

- **Pass:** The Ask flow completes normally — you get a full, coherent answer — despite the device
  having zero network connectivity. This proves the model invocation has no network dependency.
- **Fail:** The Ask flow hangs indefinitely, times out, shows an error, or otherwise fails to
  produce an answer *because of* the lack of connectivity (as opposed to some unrelated failure —
  if it fails, note what the failure looked like in the Result section so it's clear which it was).
- After the test, remember to turn Network Link Conditioner back **Off** (or Airplane Mode back
  off) so the phone returns to normal connectivity.

---

## Result

*(Leave blank until you've actually run this. Fill in after execution — do not pre-fill or
guess.)*

- **Date run:**
- **Method(s) used (A / B / both):**
- **Pass / Fail:**
- **Notes / anything observed (including any traffic attributed to Apin, or any Ask-flow failure
  under Method B, even if you judged it not to matter):**
