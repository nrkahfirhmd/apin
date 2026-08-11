# Manual Verification — Siri/Spotlight Invocation Re-check (Voice + Settings)

**For:** Kv, to execute on the physical device ("Kahfi's Phone," iPhone 17) — not something a
task-runner subagent can do (no tooling for interactive Siri voice invocation, on-device Settings
inspection, or Spotlight UI observation).

**Task:** T3 (`tasks/task-graph.md`). **Backlog item:** #3 (`planning/engineering-plan.md`) /
`memory/decisions.md`'s 2026-08-11 "Siri/Spotlight latency spike: inconclusive, blocked by an
invocation-discoverability problem worse than latency itself" entry, follow-ups (a) and (b).
**Closes (contingent on the result below):** the remainder of spec open question #3 — recorded in
T4, not by running this script itself.

This document is self-contained. You should not need to open `planning/engineering-plan.md` or
`tasks/task-graph.md` to run it.

## Why this check exists

Cycle 3's spike script (`review/manual-verification/siri-spotlight-latency-spike.md`) asked you to
time the Siri/Spotlight invocation handoff, but the result was inconclusive in a more fundamental
way: typing the invocation phrase ("Ask Apin a question" / "Ask a question in Apin") into
**Spotlight search produced no result from Apin at all** — the App Shortcut never surfaced, so no
timing trial could even start. By contrast, a question Apin had already answered in-app ("Who is
the president of America") **did** surface as a top Spotlight *content* hit. That tells us
Spotlight's content-indexing path works, but it leaves two open questions unanswered:

1. Is this gap specific to **typed Spotlight search**, or does it also affect **Siri voice**
   invocation of the same phrases? Cycle 3 only tried typed Spotlight.
2. Are the **Settings > Siri & Search > Apin** toggles ("Show in Search" / "Learn from this App")
   actually in the state they're assumed to be in? Cycle 3's script named these as a prerequisite
   to check "if Apin doesn't appear," but nobody has confirmed their actual current state.

This script isolates both of those, plus gives you a place to compare what you observe against a
build/metadata-level audit (T2) that ran the same cycle, independently.

## What you're invoking

Apin registers exactly one Siri/Spotlight entry point, `AskApinShortcutsProvider`
(`Apin/AppIntents/AskApinShortcutsProvider.swift`), which exposes `AskApinIntent`
(`ApinCore/Sources/AppIntents/AskApinIntent.swift`) via two fixed phrases:

- **"Ask Apin a question"**
- **"Ask a question in Apin"**

Neither phrase embeds the question text itself, so a successful invocation (by either voice or
typed Spotlight) hands off to the system's own prompt for the missing `query` value before
`perform()` runs and Apin opens with your question already submitted. `perform()` always uses
`supportedModes = .foreground(.immediate)` — it foregrounds the full Apin app; there is no
"answer without opening the app" path today.

**What this script does not test:** it does not re-measure latency (that's the now-moot part of
Cycle 3's script, since no trial could start). It only tests **whether the invocation surfaces at
all**, on two distinct surfaces (Siri voice, Settings state), each with its own pass/fail.

## Prerequisites

1. Apin must be installed on the phone (Debug or Release, either is fine) and have been opened at
   least once since the last install, so the system has had a chance to index/donate the App
   Shortcut.
2. Do **not** pre-adjust anything in Settings before Part B below — Part B's entire point is to
   observe the toggles' actual current state, not to fix them first and then check.
3. Have Siri enabled on the device generally (Settings > Siri & Search > "Listen for 'Siri'" /
   "Press Side Button for Siri" — at least one of these must be on for Part A; if both are off,
   turn one on first as a prerequisite, and note in the Result section that you had to enable it).

---

## Part A — Retry invocation via Siri voice

This isolates whether the gap Cycle 3 found is specific to typed Spotlight search, or also affects
voice invocation of the same App Shortcut phrases.

### Steps

1. Invoke Siri (say "Hey Siri" if enabled, or press-and-hold the Side/Home button per your
   device's configuration).
2. Once Siri is listening, say exactly: **"Ask Apin a question."**
3. Observe what happens in the next few seconds. Note precisely which of the following occurs (you
   will record this in the Result section, not just a pass/fail):
   - Siri recognizes the phrase, prompts you (verbally or on-screen) for the missing question,
     you answer, and Apin opens with the question submitted.
   - Siri recognizes the phrase but fails partway (e.g., shows an error, times out, or hands off to
     a web search instead of Apin).
   - Siri does not recognize Apin as the target at all (e.g., says it doesn't understand, offers an
     unrelated suggestion, or falls back to a generic web/Spotlight search for the literal words).
   - Something else — describe it in the Result section's Notes.
4. Repeat steps 1-3 with the second phrase: **"Ask a question in Apin."**
5. If both phrases fail to invoke Apin, try one more variant as a secondary data point (not a
   required pass/fail input, just useful context): say **"Open Apin"** (a generic app-launch
   request, not one of the two registered phrases) and note whether Siri can at least locate Apin
   by name at all — this helps distinguish "Siri doesn't know about Apin as an app" from "Siri
   knows Apin but doesn't recognize these two specific App Shortcut phrases."

### Pass / fail

- **Pass:** At least one of the two registered phrases, spoken to Siri, results in Siri correctly
  identifying Apin, prompting for (or accepting) the question, and Apin opening with the question
  submitted (regardless of how long it takes — timing is out of scope for this script).
- **Fail:** Neither phrase results in Apin opening via Siri voice — Siri either doesn't recognize
  the phrase as belonging to Apin, errors out, or silently does nothing relevant.
- Record this pass/fail **separately** from Cycle 3's typed-Spotlight result — the point of this
  script is to know whether the two invocation surfaces behave the same or differently.

---

## Part B — Re-check Settings > Siri & Search > Apin toggles

This confirms the actual current state of the two toggles Cycle 3's script named as a prerequisite
to check, rather than assuming they're already correctly configured.

### Steps

1. Open **Settings** on the phone.
2. Navigate to **Siri & Search**.
3. Scroll to find **Apin** in the app list (may be under a "Suggestions from Apps" or similar
   section depending on iOS version) and tap into it.
4. Note the exact current state (On/Off) of each of the following, exactly as they appear (label
   wording may differ slightly by iOS version — use whatever the closest current equivalent is and
   note the exact label you saw):
   - **"Show in Search"** (or equivalent — governs whether Apin's content/shortcuts can appear in
     Spotlight search results).
   - **"Learn from this App"** (or equivalent — governs whether Siri/Search uses on-device usage
     signals to improve suggestions for Apin).
5. Do not change either toggle yet. Just record their as-found state in the Result section.
6. **Only if either toggle was found Off:** turn it On, then repeat Part A (both phrases) and note
   in the Result section whether turning it on changed the outcome. If both toggles were already
   On, skip this step and note that in the Result section.

### Pass / fail

- **Pass:** Both "Show in Search" and "Learn from this App" (or their current iOS-version
  equivalents) are found **On** at the time of this check.
- **Fail:** Either toggle is found **Off**. This is a fail for the *as-found state* even if turning
  it on afterward fixes Part A — record both the as-found result and, if applicable, the
  after-toggling-on result separately, since they answer different questions (was misconfiguration
  the cause, vs. is the app still broken even with correct configuration).

---

## Part C — Cross-reference: T2's build/metadata findings

T2 (`tasks/task-graph.md`) ran an independent, build/metadata-level audit the same cycle as this
script, checking for any static/build-level cause of the invocation gap (as opposed to this
script's device/runtime-level checks). T2 is **done** as of this writing — its findings are
summarized below so you can compare what you observe in Parts A/B against what the build-level
check already ruled out. (Full detail: `tasks/task-graph.md`, T2's "Findings" subsection.)

**T2's summary: clean pass, no build-level defect found.**

- **`autoShortcuts` / `extract.actionsdata` check — PASS.** A simulator-destination build (a
  generic/device-destination build failed only on code-signing/no-dev-team, an environment gap
  unrelated to App Intents) produced a populated `autoShortcuts` array for `AskApinShortcutsProvider`
  with exactly one entry (`AskApinIntent`), both phrases present ("Ask Apin a question" / "Ask a
  question in Apin"), `shortTitle` "Ask Apin", `systemImageName` "questionmark.bubble" — matching
  the source and ADR 001's Cycle-1 finding exactly.
- **Build-log failure-signature check — did not recur for the target that matters.** The `Apin`
  app-target's `appintentsnltrainingprocessor` invocation trained both phrases successfully, no
  "No AppShortcuts found - Skipping." for that target. (A separate invocation for the
  `ApinWidgetExtension` target did log that message, but that's expected/correct — the widget
  extension has never had its own `AppShortcutsProvider`, by design.)
- **Source-drift check — PASS, no drift.** `AskApinShortcutsProvider.swift` and
  `AskApinIntent.swift` are unchanged since they originally shipped; `AskApinIntent.isDiscoverable`
  is still `true`.
- **Entitlement/Info.plist check — no gap found.** No Siri-specific entitlement or
  `NSUserActivityTypes`/`NSSiri...` Info.plist keys exist, but T2's findings state this is expected
  and not a gap: the modern `AppShortcutsProvider` mechanism this app uses doesn't require the
  legacy SiriKit entitlement/Info.plist declarations, and the build empirically produced a working
  `autoShortcuts` array without them.
- **Overall conclusion:** no build-level or static-config defect was found that would explain a
  Spotlight/Siri invocation gap. T2's own framing: this **narrows, not replaces**, the device-level
  investigation this script performs — if this script's Parts A/B also come back showing a gap,
  the cause is more likely a runtime/device-state issue (e.g., indexing not having happened yet,
  a Settings misconfiguration, a Siri/Spotlight-side recognition issue) than anything in the app's
  build output or source.

**How to use this when you fill in the Result section below:** if Part A and/or Part B come back
failing, that's *consistent* with T2's conclusion (build is clean, so the cause is elsewhere) —
it's not a contradiction. If Part A/B come back passing (i.e., Siri voice works and/or toggles were
already correctly set), that's also consistent — it would mean the gap Cycle 3 found may have been
specific to typed Spotlight search only, or transient. Either way, note in your Result section
whether your observations line up with T2's "build is clean" conclusion or seem to point at
something T2 wouldn't have caught (T2 explicitly did not test on-device Siri/Spotlight behavior
itself — only the build/metadata output that feeds it).

---

## Result

- **Date run:**
- **Part A — Siri voice invocation:**
  - Phrase 1 ("Ask Apin a question") outcome:
  - Phrase 2 ("Ask a question in Apin") outcome:
  - "Open Apin" fallback tried? Outcome (if tried):
  - Pass / Fail:
- **Part B — Settings toggles:**
  - "Show in Search" as-found state (On/Off):
  - "Learn from this App" as-found state (On/Off):
  - Pass / Fail (as-found):
  - If either was Off and you turned it on: did Part A's result change afterward?
- **Part C — comparison to T2's findings:** does your result line up with T2's "build/metadata is
  clean" conclusion, or point at something T2 wouldn't have caught?
- **Notes (anything unexpected — exact wording of any Siri/system error or fallback UI seen, iOS
  version, whether this differs from Cycle 3's typed-Spotlight result, etc.):**
