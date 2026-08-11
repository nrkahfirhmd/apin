# Decisions Log

Lightweight decisions that don't warrant a full ADR (see `adrs/` for architectural ones).
Newest first. Append, don't rewrite history.

## Format

```markdown
### YYYY-MM-DD — <one-line decision>
Context: why this came up
Decision: what we chose
Owner: who/what decided (e.g. "planner agent", "Kv")
```

---

<!-- Entries below this line, newest first -->

### 2026-08-11 — iOS 26+ / A17 Pro-or-M-series-or-later minimum re-verified a fourth time (T5, Cycle 4), still no discrepancy — standing suggestion to retire the per-cycle check restated
Context: Routine per-cycle spot-check (spec open question #1), same method as Cycle 2's T9 and
Cycle 3's re-check (see the 2026-08-11 "iOS 26+ ... re-verified" entry further below) — a fresh
live-doc fetch, not a restatement of the prior result.
Decision: T5 live-fetched the same two Apple sources again today (`FoundationModels`/
`SystemLanguageModel`'s markdown-mirror doc, and `https://www.apple.com/apple-intelligence/`) and
found no change: iOS 26.0 floor unchanged, A17 Pro (iPhone 15 Pro/Pro Max) still the
minimum-eligible iPhone chip, matching `project.yml`'s `deploymentTarget: "26.0"` (all 4 relevant
targets) and all 6 `@available` annotations in `ApinCore/Sources/AI/`, cross-checked directly. No
discrepancy found — no source edit made. Full findings: `tasks/task-graph.md` T5's "Findings"
subsection. This is the fourth independent check across four cycles (2026-08-10 original, Cycle
2's T9, Cycle 3's re-check, this cycle's T5) to land on the identical result — restating, not
deciding, the standing suggestion already made in Cycle 3's and this cycle's plan that Kv may want
to consider retiring this from active per-cycle tracking now that it has never once moved.
Owner: task-runner (T5, Cycle 4)

### 2026-08-11 — New Siri/Spotlight invocation re-check script produced and handed to Kv (T3, Cycle 4); T4 stays blocked, fourth consecutive cycle on this device-verification class
Context: Cycle 3's Siri/Spotlight latency-spike check (see the entry further below) surfaced a
more fundamental gap than latency: typed Spotlight search produced no result from Apin at all.
This cycle's backlog item 3 asked for a follow-up script isolating Siri-voice invocation from
Spotlight-typed invocation, plus a re-check of the two named Settings toggles.
Decision: T3 produced `review/manual-verification/siri-spotlight-invocation-recheck.md` — a new
file, does not touch or overwrite Kv's existing `siri-spotlight-latency-spike.md` record. Part A
covers Siri-voice invocation (two phrases plus an "Open Apin" fallback probe); Part B covers the
Settings > Siri & Search > Apin toggle re-check; Part C cross-references T2's actual build/metadata
findings (clean pass, no defect — see the entry above) rather than a stale placeholder. Result
section is genuinely blank. As with Cycle 3's equivalent scripts, this task is done when the script
exists and is hand-off-ready, not when the gap is actually diagnosed — T4 (record Kv's execution)
stays `blocked`, contingent on Kv running the script on the physical device and reporting back,
which did not happen inside this cycle's session. This is now the fourth consecutive cycle
touching this class of device-verification blocker (zero-network and Indonesian fluency both
closed in Cycle 3; Siri/Spotlight-related verification has now spanned Cycles 3 and 4) —
`tasks/task-graph.md`'s T4 notes this is worth surfacing to Kv again rather than quietly carrying
forward unremarked.
Owner: task-runner (T3, Cycle 4) / Kv (execution and report, still pending)

### 2026-08-11 — Build/metadata App Shortcut discoverability audit re-run for the current toolchain (T2, Cycle 4): clean pass, no defect found — rules out a build-level cause for the Siri/Spotlight invocation gap
Context: follow-up (c) from the "Siri/Spotlight latency spike: inconclusive..." entry further
below (Cycle 3) asked whether `AskApinShortcutsProvider`'s phrases are actually being
donated/indexed at the build/metadata level. ADR 001's own Cycle-1 verification also flagged this
mechanism as SDK-version-dependent and worth re-checking per toolchain.
Decision: T2 re-ran ADR 001's exact Cycle-1 verification method against Xcode 26.6 (a newer SDK
than ADR 001's original check). Result: clean pass, no drift — `extract.actionsdata`'s
`autoShortcuts` array is populated with `AskApinIntent`, both phrases present, `shortTitle`/
`systemImageName` match source; the `appintentsnltrainingprocessor` "No AppShortcuts found"
failure signature did not recur for the `Apin` target (a superficially similar log line for
`ApinWidgetExtension` is expected/by-design, not a recurrence — the widget has never had its own
`AppShortcutsProvider`); `isDiscoverable` still `true`; no entitlement/Info.plist gap (the modern
`AppShortcutsProvider` mechanism doesn't require the legacy SiriKit entitlement or
`NSUserActivityTypes`). Full findings: `tasks/task-graph.md` T2's "Findings" subsection. This is a
genuine negative result, not a non-finding — it narrows (does not replace) the ongoing
Siri/Spotlight invocation-gap investigation to a runtime/device-state cause, which is what T3's new
script (see the entry above) is designed to isolate. Also surfaced, not fixed: two
untracked/gitignored stray `.xcodeproj` shadow copies at repo root — see
`memory/technical-debt.md`'s new entry.
Owner: task-runner (T2, Cycle 4)

### 2026-08-11 — English-only language policy shipped in code (T1); spec open question #5 closed in code, not just as a recorded decision
Context: Kv's sign-off ("Yes, English-only") was already recorded in this file's "Answer language
resolved..." entry below, during Cycle 4's planning session. This cycle's implementation phase
(T1) turned that sign-off into shipped code.
Decision: T1 replaced `PersonalityBrief.placeholder.languagePolicy`
(`ApinCore/Sources/AI/PersonalityBrief.swift`) — previously "Mirror the language of the question
(English or Indonesian); default to English when the question's language is ambiguous." — with
"Always respond in English, regardless of the question's language." No Indonesian-mirroring
wording remains anywhere in the file. The file's header doc comment was also updated to state open
question #5 is resolved (citing this file) rather than describing the policy as "carried forward
unchanged." `PersonalitySystemInstructionBuilderTests.swift`'s one language-related assertion
(`testDefaultOutputIncludesLanguageHandlingInstruction`) reads the property dynamically and passed
unmodified — confirmed independently by `/review` (98/98 `ApinCore` tests) and `/qa` (131/131
combined, plus a source-level sanity check that the composition pipeline picked up the new value
correctly). Content-only change; `PersonalityBrief`'s shape (5 fields, same `init`) and
`PersonalitySystemInstructionBuilder`'s composition logic are unchanged. Spec open question #5 is
now closed both as a decision (already recorded below) and in shipped code.
Owner: task-runner (T1, Cycle 4)

### 2026-08-11 — Answer language resolved: English-only, mirror-language default dropped
Context: Spec open question #5 (product half). Cycle 3's Indonesian fluency check failed 0/5 (see
the entry below), paired with Kv's stated read "i think only English is enough." Per this
project's established pattern, that signal alone wasn't treated as sufficient authorization —
Cycle 4's `/plan` explicitly gated the corresponding backlog item (shrink `PersonalityBrief`'s
`languagePolicy` to English-only) on an explicit sign-off in the planning session.
Decision: Kv confirmed explicitly in Cycle 4's planning session (AskUserQuestion, "Yes,
English-only" selected over "keep mirroring" / "defer"): shrink Apin to English-only, remove the
Indonesian-mirroring language policy. This closes spec open question #5. Implementation is
Cycle 4's backlog item 1 (`ApinCore/Sources/AI/PersonalityBrief.swift`'s `languagePolicy` field),
now ungated and actionable.
Owner: Kv

### 2026-08-11 — Siri/Spotlight latency spike: inconclusive, blocked by an invocation-discoverability problem worse than latency itself
Context: T4's manual verification script (`review/manual-verification/siri-spotlight-latency-spike.md`)
asked Kv to time the deep-link handoff for both App Shortcut phrases ("Ask Apin a question" /
"Ask a question in Apin"), 3 trials each, against a derived Go/No-Go threshold (10s ceiling, 1.5×
baseline overhead). Kv attempted this on the physical iPhone 17 (11 August 2026, Spotlight typed).
Decision: No Go/No-Go call can be made — Kv reports that typing the invocation phrase into
Spotlight search **produced no result from Apin at all** (the App Shortcut didn't surface), so no
trial could even start. By contrast, a question Apin had already answered in-app ("Who is the
president of America") **did** surface as a top Spotlight search hit — meaning Spotlight's
content-indexing path works, but the App Shortcut *invocation* path (`AskApinShortcutsProvider` /
`AskApinIntent`) does not appear to be discoverable via typed Spotlight search on this device, as
of this check. Baseline, all 3 trial readings, method, and Go/No-Go are unrecorded because the
invocation never got that far. This is a more fundamental gap than the latency question T4 set out
to answer, and per T4's own script it's out of scope for T5 to silently fix — flagging as a new
backlog candidate for the next `/plan`: (a) re-attempt via Siri voice (not just Spotlight typed) to
isolate whether this is Spotlight-specific, (b) re-check the "Show in Search" / "Learn from this
App" Settings toggles the script's Prerequisites section calls out, (c) if still unreproducible,
investigate whether `AskApinShortcutsProvider`'s App Shortcut phrases are actually being
donated/indexed. Spec open question #3's remainder (Spotlight/Siri latency budget) stays open;
T13's shipped deep-link is unaffected regardless (per the script's own "Regardless of outcome").
Owner: Kv (execution/report) / task-runner (T5, recording) — investigation and resolution owned by
a future cycle

### 2026-08-11 — Indonesian fluency check: Fail (0/5); Kv's product read leans English-only
Context: T3's manual verification script (`review/manual-verification/indonesian-fluency-check.md`)
asked Kv to run 5 representative Indonesian questions through the Ask flow on the physical iPhone
17 and judge fluency against concrete pass/fail criteria, per the 2026-08-10 "Answer-language
mirroring... implemented as assumed; Indonesian support still runtime-unverified" entry below.
Decision: Kv ran all 5 questions (11 August 2026) — **Overall: Fail, 0/5**. Every question failed:
Q1 and Q5 (factual) answered in English despite being asked in Indonesian; Q2 and Q3 mixed
Indonesian with untranslated English sentences; Q4 (the longer/complex question) couldn't produce
an answer at all, apparently due to unsupported language/length combination; Q2 additionally
couldn't fetch the requested journal data. This is a clean technical fail per the script's own
criteria, not a borderline call. Separately, Kv's own read on the product question (should Apin
mirror English/Indonesian at all): **"i think only English is enough."** Per the script's explicit
framing, this technical result does not by itself resolve the product question (spec open question
#5's product half) — but Kv's stated leaning, combined with a 0/5 technical fail, is a strong
signal. No code change made in T5 (per its scope: a result surfacing a defect is a new backlog
item, not something T5 silently absorbs) — flagging shrinking the mirror-language feature to
English-only as a strong candidate for the next `/plan` to formally decide and scope, rather than
leaving the current mirror-language default shipped as-is with a known-broken Indonesian path.
Owner: Kv (execution, product read) / task-runner (T5, recording) — formal scope decision owned by
the next `/plan`

### 2026-08-11 — Zero-network check: dynamically verified, Pass
Context: T2's manual verification script (`review/manual-verification/zero-network-check.md`)
asked Kv to dynamically confirm (via Instruments or Network Link Conditioner) that the Ask flow
makes zero network requests, closing the gap left by the static-analysis-only argument recorded in
`memory/technical-debt.md`'s "Zero network requests..." entry.
Decision: Kv ran Method A (Instruments' Network instrument) on the physical iPhone 17
(11 August 2026), capturing the full window from app-open through 15s after the answer finished
streaming. Result: **Pass** — zero connections/bytes attributed to the Apin process for the entire
window, no anomalies noted. This is a genuine dynamic verification (not the prior static-only
grep argument) and closes the debt entry — see `memory/technical-debt.md`'s corresponding entry,
now marked resolved.
Owner: Kv (execution) / task-runner (T5, recording)

### 2026-08-11 — Personality brief resolved: "Apin" is an Apple Intelligence pun, tone playful/cheerful, voice modeled on Crow Armbrust (*Trails of Cold Steel*)
Context: spec open question #2, re-flagged as still-unresolved every cycle since it first shipped
as a placeholder (see the 2026-08-11 "Personality brief for 'Apin' still unresolved as of Cycle
2" entry and the 2026-08-10 placeholder entry, both below). Kv supplied a real brief in this
cycle's planning session chat.
Decision: name is framed as a pun on "Apple Intelligence"; tone is playful/cheerful; character
reference is Crow Armbrust — witty, charming, mercenary-rogue energy, quips rather than lectures,
cocky but likable, still always answers the actual question directly, dials back the swagger for
serious/sensitive/safety-relevant topics. Implemented as a content-only change in T1
(`ApinCore/Sources/AI/PersonalityBrief.swift`, Cycle 3) — behavior-anchored guidance only, no
backstory/setting/character-name lore encoded, per the plan's Risk mitigation against
overshooting into roleplay. `PersonalitySystemInstructionBuilderTests.swift` passes unmodified in
shape; verified independently by both `/review` and `/qa`. Closes spec open question #2 — Apin's
name origin and character reference are no longer open.
Owner: Kv (brief content) / task-runner T1 (Cycle 3, implementation)

### 2026-08-11 — Retention/archiving policy resolved: keep current behavior (keep-forever, manual single-delete)
Context: spec open question #4, re-flagged as still-open every cycle since it first shipped as an
assumption in Cycle 1's T6 (see the 2026-08-10 "implemented as assumed" entry and the 2026-08-11
Cycle-2 re-check entry, both below). Kv confirmed in this cycle's planning session chat.
Decision: keep the already-shipped behavior as final — journal entries are kept forever by
default, manual single-entry delete remains the only deletion path in scope; no soft-delete,
archive, or auto-expiry. No code change needed (`SwiftDataJournalRepository.swift` already
matches this exactly, re-confirmed during this cycle's plan). Closes spec open question #4.
Owner: Kv

### 2026-08-11 — T13 Spotlight/Siri deep-link auto-submit UX resolved: keep current behavior
Context: spec open question #3 (partial — the T13 auto-submit sub-question), re-flagged as
still-open every cycle since T13 shipped in Cycle 1 (see the 2026-08-10 entry and the 2026-08-11
Cycle-2 re-check entry, both below). Kv confirmed in this cycle's planning session chat.
Decision: keep auto-submit-on-deep-link as final, shipped behavior — a Spotlight/Siri query
continues to fire `AskViewModel.submit()` immediately once `AskView` picks up the prefilled
query, with no confirming tap required first. No code change. This closes the T13 sub-question
specifically; the broader spec open question #3 (Spotlight/Siri latency budget) is separate and
remains addressed only by T4's manual verification script this cycle (see the entry below),
carried forward via T5.
Owner: Kv

### 2026-08-11 — T4/T5/T10-equivalent device verification: manual scripts produced and handed off, Kv driving the device personally (updates the entry below)
Context: follow-up to the 2026-08-11 "T4/T5/T10 blocked on execution-environment tooling" entry
below, where Kv had chosen option (c) — defer to cycle 3. This cycle's `/plan` scoped the
carried-forward items (renumbered T2/T3/T4 in `tasks/task-graph.md`) as producing precise,
self-contained manual verification scripts rather than having the session attempt a CLI-only
proxy, and Kv explicitly confirmed choosing to drive the physical device personally this cycle
rather than have the session attempt that proxy.
Decision: task-runners produced `review/manual-verification/zero-network-check.md`,
`review/manual-verification/indonesian-fluency-check.md`, and
`review/manual-verification/siri-spotlight-latency-spike.md` — each self-contained, with concrete
pass/fail criteria and a genuinely blank "Result" section — and handed them to Kv. As of this
cycle's end, Kv has not yet executed any of the three scripts or reported results, so T5 (record
Kv's results) stays `blocked`, and the three underlying open items (zero-network dynamic
verification, Indonesian fluency, Siri/Spotlight latency budget) remain open — the difference
from prior cycles is that executable scripts now exist and are handed off, not that the
verification itself has happened. This is the third consecutive cycle this class of item hasn't
closed (cycle 1: no hardware; cycle 2: no device-driving tooling; cycle 3: scripts exist,
execution now depends only on Kv's own time). `planning/engineering-plan.md`'s Open Questions #3
flags: if this recurs into cycle 4, consider pulling these out of the sprint-planning loop into a
standing, cycle-independent checklist.
Owner: task-runner (T2/T3/T4, Cycle 3) / Kv (execution and report, still pending)

### 2026-08-11 — T4/T5/T10 blocked on execution-environment tooling, not hardware availability; Kv chose to defer to cycle 3
Context: Cycle 2's plan and task graph anticipated T4 (dynamic zero-network verification), T5
(Indonesian fluency check on real hardware), and T10 (inline Siri/Spotlight latency spike) being
blocked on physical Apple Intelligence-capable hardware and an active Apple Developer account
being *available* at all. Partway through this cycle, Kv's iPhone 17 ("Kahfi's Phone") became
`connected` via `devicectl` (first observed by `/qa`, flagged as a non-blocking informational
note in `review/qa-report.md`), and Kv separately confirmed both a physical iPhone 17 and an
active Apple Developer account are available in principle. So the hardware-availability
assumption `tasks/task-graph.md`'s "Blocked / notes" section was written against no longer holds.
Decision: The actual blocker turned out to be different from what was planned for: the
orchestrating CLI session that runs `/implement` has no tooling to interactively drive a
*physical* device's UI — T4's Instruments network capture, T5's manual typing of real Indonesian
questions and fluency assessment, and T10's latency measurement all require live human-style
interaction with a physical device (Instruments capture UI, on-device typing, timing a real
response) that no available tool in this session can perform; all available device tooling in
this session is Simulator-only (`xcodebuild`/`xcrun simctl`), and even `devicectl`'s
`connected` state doesn't give this session a way to drive the device's UI. Kv was asked directly
whether to (a) drive the device themselves this session, (b) have this session attempt a
CLI-only best-effort proxy (e.g. static analysis plus simulator-only checks, explicitly
disclosed as not equivalent), or (c) defer T4/T5/T10 to cycle 3 for a session/context with real
device-UI-driving tooling (e.g. a human-in-the-loop pass, or a future Instruments-capable
automation). Kv explicitly chose (c), defer to cycle 3. This is a meaningfully different blocker
than cycle 2's plan anticipated — cycle 3's `/plan` should scope T4/T5/T10 (or their
cycle-3-renumbered equivalents) explicitly around needing a device-UI-driving execution context
(human-in-the-loop or equivalent tooling), not just "hardware available," since hardware alone is
no longer the gating factor.
Owner: Kv (explicit choice, this cycle's orchestrating session) — visible to cycle 3's `/plan`

### 2026-08-11 — Retention/archiving policy still unconfirmed by Kv (re-checked, still open)
Context: T7 (backlog item #7, spec open question #4) re-checked whether Kv has responded on
retention/archiving policy — keep-forever + manual single-delete (as currently shipped, see the
2026-08-10 entry below) vs. a different policy such as soft-delete/archive or auto-expiry — before
defaulting to the still-open outcome, per T7's own scope framing.
Decision: Searched the orchestrating session, `planning/spec.md` (open question #4 is still listed
unresolved), and the repo tree for any scratch note or message from Kv — found none. Also read the
current state of `ApinCore/Sources/Persistence/SwiftDataJournalRepository.swift` (post-T1, which
landed this cycle and changed `fetch(by:)`/`delete(id:)`'s multi-match handling and added
`deduplicateEntries()`): confirmed T1's changes are purely about `id`-collision handling, not
retention policy — no auto-archive/expiry/soft-delete logic was introduced anywhere in the
repository layer, so the file's current state still matches the keep-forever, manual
single-delete-only policy described below with nothing needing reconciliation. No code change
made this cycle either. Re-flagging the 2026-08-10 entry below as still open rather than rewriting
it, per this file's append-only convention. Carry forward into the next `/plan` as still-open
question #4.
Owner: task-runner (T7, Cycle 2) — resolution still owned by Kv

### 2026-08-11 — Personality brief for "Apin" still unresolved as of Cycle 2 — re-flagged, not re-litigated
Context: T6 (backlog item #6, spec open question #2) ran again this cycle to check whether Kv
had supplied a real personality brief (name origin, tone/character reference) anywhere
discoverable in the repo — `planning/spec.md`, the engineering plan, a scratch file, or updated
comments/content in `ApinCore/Sources/AI/PersonalityBrief.swift` — before defaulting to the
still-open outcome, per T6's own notes.
Decision: Checked all plausible surfaces (spec.md open question #2 text unchanged,
engineering-plan.md backlog item #6 unchanged, no scratch/brief/Kv-authored files found in the
repo tree, `PersonalityBrief.swift`'s `.placeholder` content byte-for-byte identical to what T5
shipped in cycle 1, no relevant git history beyond the single base commit) — no real brief has
been supplied anywhere discoverable as of this cycle. No code change made; this remains the
expected, acceptable outcome per T6's scope framing ("purely content-blocked... no design work
left, only waiting on the actual brief text"). Carrying forward into the next `/plan` as still
open — resolution still owned by Kv.
Owner: task-runner (T6, Cycle 2) — resolution owned by Kv

### 2026-08-11 — T13's auto-submit-on-Spotlight-deep-link UX still unconfirmed by Kv (re-checked, still open)
Context: T8 (backlog item #8, spec open question #3 partial) checked whether Kv has responded on
whether Spotlight/Siri deep-link queries should keep auto-submitting immediately (T13's shipped
cycle-1 behavior, see the 2026-08-10 entry below) or require a confirming tap first before
`AskViewModel.submit()` fires.
Decision: Searched the orchestrating session, `planning/spec.md` (open question #3 is still
listed unresolved), and the repo for any scratch note or message from Kv — found none. Kv has
not responded this cycle either. No code change made; the shipped auto-submit behavior remains
as-is. Re-flagging the 2026-08-10 entry below as still open rather than rewriting it, per this
file's append-only convention. Carry forward into the next `/plan` as still-open question #3.
Owner: task-runner (T8, Cycle 2) — resolution still owned by Kv

### 2026-08-11 — iOS 26+ / A17 Pro-or-M-series-or-later minimum re-verified against live Apple docs, no discrepancy found
Context: T9 (backlog item #9, spec open question #1) re-checked the deployment-target/hardware
assumption again this cycle, per the plan's explicit note that Apple has moved this bar before
and it should be spot-checked every cycle, not treated as permanently settled by the 2026-08-10
verification below.
Decision: Live-fetched two current Apple sources today (2026-08-11) and confirmed both match the
codebase's existing assumption with no discrepancy:
  - Apple Developer documentation for `FoundationModels`/`SystemLanguageModel`
    (`https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel`, fetched via
    its markdown mirror at `https://docs.developer.apple.com/tutorials/data/documentation/
    foundationmodels/systemlanguagemodel.md`) lists the framework's availability floor as
    `iOS: 26.0.0 -`, `iPadOS: 26.0.0 -`, `macCatalyst: 26.0.0 -`, `macOS: 26.0.0 -`,
    `visionOS: 26.0.0 -`. It also notes 3 on-device model versions now exist, aligned to
    "26.0–26.3", "26.4", and "27.0" — confirming iOS 27 exists as of this check but not lowering
    or changing the 26.0 floor.
  - Apple's official Apple Intelligence device-support page
    (`https://www.apple.com/apple-intelligence/`, fetched today) lists iPhone 15 Pro / iPhone 15
    Pro Max (A17 Pro) as the minimum-eligible iPhone chip (alongside all iPhone 16 and iPhone 17
    variants), iPad Pro/iPad Air with "M1 and later", iPad mini with "A17 Pro", Apple Vision Pro
    with "M2 and later", and Mac models with "M1 and later" (plus a newer "MacBook Neo (A18
    Pro)" entry). This matches "A17 Pro-or-M-series-or-later" exactly — no discrepancy.
  Cross-checked against the current codebase for consistency (not changed, per T9's scope):
  `project.yml` sets `deploymentTarget: "26.0"` on all 4 relevant targets, and every
  `@available(...)` annotation in `ApinCore/Sources/AI/` (`AssistantSessionService.swift`,
  `AsyncTimeout.swift`, `CapabilityGate.swift`, `FoundationModelsSessionAdapter.swift`,
  `LanguageModelSessionProviding.swift`, `ModelHardwareAvailabilityProviding.swift`,
  `OSVersionProviding.swift`) gates at `iOS 26.0`/`macOS 26.0`/`visionOS 26.0`. Also confirmed
  `ModelHardwareAvailabilityProviding.swift`'s `DefaultModelHardwareAvailabilityProvider`
  deliberately does not hardcode a chip/device allowlist — it defers entirely to
  `SystemLanguageModel.default.availability` at runtime, so even if Apple revises the exact
  device list again in a future OS update, this code path tracks it automatically without needing
  a code change (only `project.yml`'s `deploymentTarget` would ever need bumping, if Apple raises
  the minimum OS floor itself).
  No discrepancy found this cycle — no new backlog candidate needed. Still worth re-spot-checking
  in future cycles per the same reasoning as the 2026-08-10 entry below.
Owner: task-runner (T9)

### 2026-08-10 — T13's auto-submit-on-Spotlight-deep-link is unconfirmed product UX, not yet a settled call
Context: T13's `AskApinIntent` deep-link auto-submits the prefilled query via
`AskViewModel.submit()` as soon as `AskView` picks it up, rather than requiring a second manual
tap after the deep-link opens the app. The rationale (documented in `AskView.swift`'s header
and re-verified by both `/review` and `/qa`) is that a Spotlight/Siri query already represents a
fully-typed question, so requiring an extra tap is worse UX for satisfying Req 5's baseline.
Decision: Ship auto-submit-on-deep-link as the cycle-1 behavior, but flag it explicitly as a
product/UX judgment call that needs Kv's confirmation, not an implementation detail settled by
the task-runner alone.
Owner: task-runner (T13), confirmed unresolved by reviewer + qa-validator

### 2026-08-10 — Answer-language mirroring (English/Indonesian) implemented as assumed; Indonesian support still runtime-unverified
Context: `planning/spec.md` open question #5 and the plan's stated default: answers should
mirror the question's language (English or Indonesian), defaulting to English when detection is
ambiguous. T4/T5 implemented this as the default behavior.
Decision: Ship the mirror-language default as assumed. Whether the on-device
`FoundationModels` model on Kv's actual hardware genuinely produces fluent Indonesian output has
not been verified this cycle (no real-device access) — this needs a hands-on check before it can
be considered confirmed, not just implemented-as-assumed. If unsupported, scope should shrink to
English-only per the plan's own risk mitigation, surfaced back to Kv rather than silently
degraded.
Owner: planner (assumption) / task-runner T4-T5 (implementation) — verification still open

### 2026-08-10 — Retention policy (keep-forever, manual single-delete only) implemented as assumed
Context: `planning/spec.md` open question #4; the plan assumed entries are kept forever by
default with no automatic archiving/deletion, and manual single-entry delete as the only
deletion path in scope.
Decision: Implemented exactly as assumed in T6 — no auto-archive/expiry logic exists anywhere
in the repository layer. Not yet explicitly confirmed by Kv; low cost to revisit later since
no other task depends on entries being finite.
Owner: planner (assumption) / task-runner T6 (implementation)

### 2026-08-10 — Deployment-target assumption (iOS 26+, Apple Intelligence hardware) was verified, not just assumed
Context: `planning/engineering-plan.md` flagged the iOS 26+ / A17 Pro-or-M-series-or-later
minimum as an explicit assumption needing re-verification against current Apple developer docs
before/at T1, since Apple has moved this bar before.
Decision: T1 re-checked this against live Apple developer documentation during implementation
(not carried forward as an unverified guess) and confirmed the assumption was correct as
stated — no discrepancy was found or flagged in T1's completion notes. Treat this specific
figure as verified-as-of-cycle-1, not merely assumed, though it should still be spot-checked
again in future cycles since Apple can move it.
Owner: task-runner (T1)

### 2026-08-10 — Personality brief for "Apin" remains a placeholder pending Kv's real brief
Context: `planning/spec.md` open question #2 — is "Apin" short for something, and is there a
specific tone/character reference beyond "has personality"? The plan's default: a warm,
curious, encouraging study-buddy voice, concise and plain-language, never condescending, admits
uncertainty.
Decision: T5 implemented this placeholder brief exactly as stated, deliberately as isolated,
swappable data (not hardcoded prose scattered across call sites) so replacing it later is a
content change, not a code change. This remains unresolved and open — carry forward into the
next `/plan` as still-open question #2.
Owner: planner (assumption) / task-runner T5 (implementation) — resolution owned by Kv
