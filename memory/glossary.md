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
on-device, offline study-buddy companion. The personality brief (tone/voice) is currently a
placeholder pending Kv's real intent — see `memory/decisions.md`. (Context: name is not
confirmed to be short for anything; open question from `planning/spec.md`.)

**ask-and-save flow** — the shared "capture question → run the on-device model → save the Q&A
pair to the journal" orchestration (`AskAndSaveServicing`/`AskAndSaveService`, T8), reused by
the Ask screen, the Spotlight deep-link (T13), and the widget quick-ask button (T17) so no entry
point duplicates or drifts from the others. (Context: lives in the `Apin` app target, not
`ApinCore` — see `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`.)

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

**digest / streak** — the weekly-digest view's two computed metrics: the count of questions asked
and the current consecutive-day streak, both derived purely from `JournalEntry.createdAt`
(`JournalDigest.compute(from:calendar:now:)`). "Streak" breaks on any calendar day with zero
journal entries. (Context: introduced T12, Cycle 2; see `memory/apis.md`.)

**tag filter (in-memory)** — journal search's tag-matching condition
(`JournalQuery.tagFilter`/`applyTagFilter(to:)`), AND-combined with keyword/date-range filtering
but applied as a separate, in-memory, post-fetch `Array` filter rather than folded into the
SwiftData `#Predicate` used for the rest of the query — a confirmed SwiftData limitation on
`[String]` `@Model` properties, not a style choice. (Context: introduced T11, Cycle 2; see
`memory/adrs/003-in-memory-post-fetch-tag-filtering.md`.)
