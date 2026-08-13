# Glossary / Domain Terminology

Project-specific and domain terms, acronyms, and internal shorthand. Any agent hitting an
unfamiliar term should check here first, and add it if missing.

## Format

```markdown
**Term** — plain-language definition. (Context: where/why it's used, if not obvious.)
```

---

<!-- Terms below this line, alphabetical -->

**App Group store** — the shared SwiftData/App Group container (`group.com.apin.app`, file
`ApinJournal.sqlite`) that the `Apin` app target and the `ApinWidget` extension both
independently construct a `ModelConfiguration`/`ModelContainer` against, so the widget can read
real journal data written by the app despite running in a separate process. See
`memory/adrs/002-shared-app-group-swiftdata-store-for-widget.md`. (Context: introduced in T16,
only fully functional once T18 wired the app-side half.)

**Apin** — the assistant's name and personality; the whole product is named after it. Kv's
on-device, offline study-buddy companion. The name is a pun on "Apple Intelligence"; the
personality brief's tone is playful/cheerful, voice modeled on Crow Armbrust (*Trails of Cold
Steel*: witty, charming, mercenary-rogue energy, quips over lectures, cocky but likable, still
always answers directly) — resolved Cycle 3, see `memory/decisions.md`'s 2026-08-11 "Personality
brief resolved" entry and `ApinCore/Sources/AI/PersonalityBrief.swift`. Spec open question #2 is
now closed.

**ask-and-save flow** — the shared "capture question → run the on-device model → save the Q&A
pair to the journal" orchestration (`AskAndSaveServicing`/`AskAndSaveService`, T8), reused by
the Ask screen, the Spotlight deep-link (T13), and the widget quick-ask button (T17) so no entry
point duplicates or drifts from the others. (Context: lives in the `Apin` app target, not
`ApinCore` — see `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`.)

**AskResponse** — the `@Generable` structured-generation shape for a single ask: `answer`,
`followUpQuestion`, `chips: [String]`, `tags: [String]`, produced by one on-device model call via
`AssistantSessionService.sendStructured(prompt:)`. Additive alongside the existing plain-`String`
`send`/`streamResponse` methods, not a replacement. (Context: introduced T2, Cycle 5; no UI
consumer yet besides T4's tags-seeding — the follow-up-chips/message-history UI is deferred Stage
B. See `memory/apis.md` and `memory/adrs/004-structured-generation-supports-partial-streaming.md`.)

**capability gate** — the typed, single-source-of-truth check for whether the current
device/OS/Apple-Intelligence-toggle state supports on-device `FoundationModels` inference
(`CapabilityGating` protocol, `CapabilityGateResult` — `available` / `unsupportedDevice` /
`unsupportedOS` / `appleIntelligenceDisabled` / `modelNotReady`). (Context: every entry point —
Ask screen, widget, App Intent — branches on this instead of re-deriving availability itself.)

**capability-gate debug override** — a `#if DEBUG`-only mechanism
(`CapabilityGateDebugOverride`/`ForcedCapabilityGate`) that forces any `CapabilityGateResult`
case at launch via the `APIN_DEBUG_CAPABILITY_OVERRIDE` environment variable, used to manually
render and verify the unsupported-device/OS negative path in Simulator without needing
genuinely-ineligible physical hardware. Compiled out of Release builds entirely — never reachable
in a shipped app. (Context: introduced T3, Cycle 2; see `memory/apis.md`.)

**design handoff** — the high-fidelity UI/UX spec (`design_handoff_apin/`) that landed after
Cycle 4 closed, covering two screens (Ask + answer, Journal) in exacting detail (colors, type,
spacing, copy, interaction model). Not itself code — the task is to recreate it pixel-accurately
in SwiftUI. Split into Stage A/Stage B (see those terms) because its full scope was larger than
any prior cycle. (Context: `planning/engineering-plan.md` v1.4, Cycle 5.)

**design-token layer** — `Apin/DesignSystem/` (`ApinColor`/`ApinFont`/`ApinIcon`/`ApinRadius`/
`ApinSpacing`), five case-less namespace `enum`s translating the design handoff's
`apin-green.css` token sheet into Swift constants (OKLCH colors pre-converted to sRGB at
definition time, SF Pro font sizes/weights, SF Symbol icon names, spacing/radii). App-target-only
— never `ApinCore`, which must never import SwiftUI/UIKit. (Context: introduced T1, Cycle 5;
zero consumers until Stage B, next cycle. See `memory/apis.md`.)

**digest / streak** — the weekly-digest view's two computed metrics: the count of questions asked
and the current consecutive-day streak, both derived purely from `JournalEntry.createdAt`
(`JournalDigest.compute(from:calendar:now:)`). "Streak" breaks on any calendar day with zero
journal entries. (Context: introduced T12, Cycle 2; see `memory/apis.md`.)

**Stage A / Stage B** — this project's own vocabulary (first used Cycle 5) for splitting one
design-handoff-driven cycle into a committed-scope stage and a deferred-scope stage when a
`/plan` finds the full scope materially larger than usual. Stage A = foundation (design tokens,
structured model output, root nav — no new user-visible screen). Stage B = pixel-accurate screen
recreation, consuming Stage A's foundation. Not a permanent phase name for every future cycle —
re-evaluate per `/plan` whether a given cycle's scope actually warrants the split. (Context:
`planning/engineering-plan.md` v1.4; Kv confirmed Stage A only for Cycle 5, see
`memory/decisions.md`.)

**tag filter (in-memory)** — journal search's tag-matching condition
(`JournalQuery.tagFilter`/`applyTagFilter(to:)`), AND-combined with keyword/date-range filtering
but applied as a separate, in-memory, post-fetch `Array` filter rather than folded into the
SwiftData `#Predicate` used for the rest of the query — a confirmed SwiftData limitation on
`[String]` `@Model` properties, not a style choice. (Context: introduced T11, Cycle 2; see
`memory/adrs/003-in-memory-post-fetch-tag-filtering.md`.)
