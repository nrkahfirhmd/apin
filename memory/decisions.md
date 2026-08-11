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
