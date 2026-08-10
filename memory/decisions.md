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
