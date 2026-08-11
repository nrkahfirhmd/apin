# Manual Verification — Siri/Spotlight Latency Spike (Go/No-Go)

**For:** Kv, to execute on the physical device ("Kahfi's Phone," iPhone 17) — not something a
task-runner subagent can do (no tooling for interactive device/Siri/Spotlight/timing capture).

**Task:** T4 (`tasks/task-graph.md`). **Backlog item:** #4 (`planning/engineering-plan.md`).
**Closes (contingent on the result below):** the remainder of spec open question #3 ("Exact
Spotlight behavior... or some combination?") — recorded in T5, not by running this script itself.

This document is self-contained. You should not need to open `planning/engineering-plan.md` or
`tasks/task-graph.md` to run it.

## Why this check exists — and what it is *not*

This is a **spike**, not a release blocker. T13 already shipped the Spotlight/Siri entry point
as a **deep-link**: invoking it opens Apin, prefills your question, and auto-submits it through
the exact same on-device model path the in-app "Ask" button uses (see
`ApinCore/Sources/AppIntents/AskApinIntent.swift` and `Apin/Features/Ask/AskView.swift`'s
`applyPendingDeepLinkQueryIfNeeded()`). That already satisfies spec Req 5 ("Apin is invocable
from iOS Spotlight search"), and it is **not going away regardless of what this script finds** —
see "Regardless of outcome" at the bottom.

What's still open is whether that deep-link's *end-to-end latency* (from saying/typing the
Siri/Spotlight invocation to seeing the finished answer) feels acceptably fast, or whether it's
slow enough to be worth a future cycle investigating an inline (no-app-open) answer path instead
(that would be new scope, tracked separately — not something this script or T13 does). This
script measures that latency once, on real hardware, and gives you a go/no-go call.

## What you're actually invoking

Apin currently registers exactly one Siri/Spotlight entry point,
`AskApinShortcutsProvider` (`Apin/AppIntents/AskApinShortcutsProvider.swift`), which exposes
`AskApinIntent` (`ApinCore/Sources/AppIntents/AskApinIntent.swift`) via two fixed phrases:

- **"Ask Apin a question"**
- **"Ask a question in Apin"**

Neither phrase embeds the question text itself (the intent's `query` parameter isn't part of
either phrase pattern) — so invoking either phrase, by voice via Siri or by typing/tapping it in
Spotlight, will hand off to the system's own prompt for the missing `query` value (Siri will ask
you for it verbally; Spotlight/Shortcuts will show a text-entry step) before `perform()` runs and
Apin opens with your question already submitted. You'll see exactly which of those happens when
you run this — note it in the Result section, it isn't fully predictable from reading the code
alone.

Once `perform()` runs, `AskApinIntent` always uses `supportedModes = .foreground(.immediate)` —
it foregrounds the full Apin app and runs in-process. There is no "answer without opening the
app" path today (that's explicitly out of scope per `AskApinIntent`'s own header, deferred to a
separate, optional future task). This matters for how you time the measurement below: the
window you're timing spans real app-process launch/foreground *and* model inference, not model
inference alone — both are inherent to the shipped invocation path.

## Prerequisites

1. Apin must be installed on the phone (Debug or Release, either is fine) and have been opened at
   least once, so the system has had a chance to index/donate the App Shortcut.
2. On the phone: **Settings > Siri & Search > Apin** — confirm "Show in Search" and "Learn from
   this App" (or equivalent, depending on iOS version) are enabled. If Apin doesn't appear as a
   suggestion in Spotlight or isn't recognized by Siri at all, check here first before assuming
   the intent itself is broken.
3. Pick one representative question and use the **same one for every trial** below, so trials are
   comparable to each other and to the in-app baseline in step 2 of "Measure": **"What's a good
   way to start a daily journaling habit?"** (same question T2's script uses, for consistency —
   any ordinary question works, but keeping it fixed across trials is what makes the comparison
   meaningful).
4. A stopwatch you can start/stop with one hand while holding/watching the phone — the iPhone's
   own Stopwatch app (Control Center or the Clock app) is precise enough (records to
   hundredths of a second) and is what "Method A" below assumes. Do not try to also operate the
   stopwatch and Siri/Spotlight with the same hand if that's awkward — use whichever
   hand/device split is comfortable, timing accuracy matters more than method purity.

## How to time it — Method A (stopwatch, required)

Run this for **both** invocation phrases at least once each (so you've exercised both wordings),
and run the phrase(s) you end up using **3 times each**, noting all readings, not just one — a
single trial can be thrown off by an unrelated hiccup (e.g., a background index, a cold app
launch after a device reboot vs. a warm one already in memory).

### Start the stopwatch at the right moment — this is the part that's easy to get wrong

Do **not** start timing when you begin speaking to Siri or begin typing in Spotlight — how long
*you* take to say/type the question is not part of what this script measures (it's you, not
Apin). Instead:

- **If invoked by voice (Siri):** Start the stopwatch the instant Siri finishes asking for the
  query and you finish giving your answer — practically, start it the moment Siri's UI stops
  waiting for your voice input and visibly begins handing off (Siri's "thinking" indicator
  appears, or the screen begins transitioning toward Apin). If Siri repeats your question back to
  confirm before proceeding, start the stopwatch after that confirmation, not before.
- **If invoked via Spotlight (typed):** Start the stopwatch the instant you tap whatever
  UI element finally commits the question (e.g., a "Done"/checkmark/return on the system's
  parameter-entry step) and the screen begins transitioning toward Apin.

In both cases, the intent is the same: **start timing only once the question itself has been
fully handed to the system and Apin's launch/foreground is what's actually happening next** —
that's the part whose latency this script cares about.

### Stop the stopwatch at the right moment

Apin's Ask screen moves through three visibly distinct states after your question lands
(`Apin/Features/Ask/AskView.swift`'s `answerSection`): a "Thinking…" spinner, then streaming
partial answer text (still showing a small progress indicator alongside it), then the final
answer with **no progress indicator at all** and the text no longer changing. Stop the stopwatch
the instant the text **stops updating and the progress indicator disappears** — that's the
`.answered` state, i.e., the full answer is done. Don't add a buffer/grace period the way T2's
network check does (that check was watching for delayed network calls; this one just wants the
real "done" timestamp).

Record each trial's reading immediately (write it down or into Notes) — don't rely on memory
across 3+ trials.

## How to time it — Method B (optional, more precise, video-based)

Use this only if Method A's readings feel too imprecise/inconsistent (human reaction time on a
handheld stopwatch is realistically ±0.2–0.3s) and you want tighter numbers. This is **not** a
true Instruments signpost trace: the app currently emits no `os_signpost`/`OSLog` markers around
the ask flow (confirmed by inspecting `Apin/` and `ApinCore/Sources/` — there's nothing to
correlate an Instruments timeline against), and adding that instrumentation would be a code
change, which is out of scope for this task. So "more precise" here means frame-accurate video
review, not deeper system tracing:

1. Mirror the iPhone's screen to your Mac (QuickTime Player > File > New Movie Recording > select
   the iPhone as the camera source, or Screen Recording via a cable/AirPlay).
2. Record a trial exactly as in Method A (same start/stop visual cues), but let the Mac's
   recording capture it instead of/in addition to a handheld stopwatch.
3. Afterward, scrub the recording frame-by-frame in QuickTime (the scrubber shows timestamps) to
   find the exact frame where the handoff begins and the exact frame where the answer text stops
   changing/the progress indicator disappears. Subtract the two timestamps.
4. This trades stopwatch reaction-time error for video frame-rate granularity (still not perfect,
   but tighter) — use it to sanity-check Method A's readings, not as a replacement requirement.

## Budget to compare against

### First: check for an official Apple figure

Apple does not appear (as of this session, unverified beyond what's checkable from source code
and this repo — this is exactly the kind of thing that needs live doc lookup, which this session
can't do) to publish a single universal "App Intent execution time budget" in milliseconds that
unambiguously applies to `AskApinIntent`'s specific mode, `supportedModes = .foreground(.immediate)`
(which behaves like a normal full-app foreground launch, not like the tightly time-boxed
execution window documented for some other App Intents contexts, e.g. interactive widget/Control
Center button intents). Before relying on this script's derived numbers below, check yourself:

- `developer.apple.com/documentation/appintents` — the `AppIntent` protocol page and the
  `IntentModes`/`supportedModes` / `foreground` documentation specifically, for any stated timing
  language.
- Apple's WWDC sessions on App Intents (search "App Intents" on developer.apple.com/videos —
  there's a new one most years; check the most recent one available at the time you run this) for
  any mentioned timeout/latency guidance.
- Apple Developer Forums, searching "App Intents timeout" or "App Intents execution time" for any
  Apple-engineer-confirmed figures.

If you find an authoritative figure that's stricter than the derived threshold below, use it
instead and note the source (URL) in the Result section. If you find nothing (plausible — this
may genuinely not be a published number for the foreground/immediate mode), proceed with the
derived threshold below and note that you checked and found nothing.

### Derived threshold (concrete, use this if no stricter official figure exists)

1. **Baseline (isolates pure inference + UI latency, no Siri/Spotlight handoff):** open Apin
   directly (not via Siri/Spotlight), type the same representative question into the "Ask Apin
   something…" field, tap **Ask**, and time from the tap to the `.answered` stable state using
   the same stop-cue as Method A. Do this once or twice — this is your baseline, not a spike
   trial.
2. **Handoff overhead** = (each Siri/Spotlight trial's reading) − (baseline reading).
3. **Go/No-Go:**
   - **Go** if every Siri/Spotlight trial's total time is **under 10 seconds**, AND handoff
     overhead in every trial is **no more than 1.5× the baseline** (e.g., if baseline is 4s,
     overhead per trial should add no more than 2s, for a total under 6s in that example — the
     absolute 10s ceiling is the hard outer bound regardless).
   - **No-Go** if any trial's total time is **10 seconds or more**, or handoff overhead exceeds
     1.5× baseline in more than one of the three trials (one outlier trial is tolerated — device
     hiccups happen — but a consistent pattern across 2+ trials is a real signal, not noise), or
     if Siri/the system ever shows its own timeout/error/fallback UI (e.g., Siri saying it's
     "having trouble" or giving up) during any trial, regardless of whether Apin eventually did
     answer.
   - The **10 seconds and 1.5×** figures above are this script's own conservative, explicitly
     derived engineering judgment call (a "should feel prompt for a voice/quick-action
     interaction" ceiling), **not** a number sourced from an Apple API doc — that distinction
     matters if you're deciding how much weight to put on a borderline result. If you found a
     stricter or more authoritative Apple-documented figure per the section above, use that
     instead and say so in the Result section.

## Regardless of outcome

This is a spike. Whether the result is Go or No-Go, **T13's shipped deep-link stays the
Spotlight/Siri entry point** — nothing about running this script or its result triggers any code
change, rollback, or removal. A No-Go result means "worth a future cycle scoping an inline
answer path as new, separately-planned work," not "T13 is broken" or "revert T13." Do not treat
this script's result as blocking anything currently shipped.

## Result

- **Date run:** 11 August 2026
- **Invocation(s) tried (Siri voice / Spotlight typed / both):** Spotlight typed
- **Official Apple figure found? (source URL, or "none found, checked as described above"):** none found
- **Baseline (in-app, no Siri/Spotlight) reading(s):**
- **Trial 1 reading (phrase used):** 
- **Trial 2 reading (phrase used):**
- **Trial 3 reading (phrase used):**
- **Method used (A / B / both):**
- **Go / No-Go:**
- **Notes (anything unexpected — e.g. which prompt UI Siri/Spotlight actually showed for the
  missing query, any timeout/error UI seen, device state warm vs. cold launch, etc.):** I tried to ask question through iPhone search feature, but it doesn't produce any result from Apin. But instead, if I ask something that already answered in-app, "Who is the president of America", Apin answers become top hit in iPhone search feature.
