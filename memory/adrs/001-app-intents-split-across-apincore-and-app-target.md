# 001. App Intents orchestration split across `ApinCore` and the `Apin` app target

Status: Accepted
Date: 2026-08-10
Sprint: Sprint 1 (see memory/sprint-summary.md)

## Context

`planning/engineering-plan.md`'s architecture decisions stated: "App Intents and widget code
live in the shared `ApinCore` package, not duplicated per extension target" — the intent being
that the widget's quick-ask button and the Spotlight `AskApinIntent` trigger the same "capture
question → run model → save to journal" flow via one shared implementation living entirely in
`ApinCore/Sources/AppIntents`.

During T13 (`AskApinIntent` — Spotlight/Siri deep link) and T17 (widget quick-ask), two real
constraints surfaced:

1. The actual "ask + save" orchestration (`AskAndSaveServicing`/`AskAndSaveService`, built in
   T8) depends on `AssistantSessionProviding`, which is intentionally scoped to the app target
   (it wraps app-target-only session/UI concerns). Moving it into `ApinCore` would have meant
   either pulling app-target-only dependencies into the shared package, or refactoring a
   working, already-tested T8 seam mid-cycle for no functional gain.
2. `AppShortcutsProvider` (the type that registers `AskApinIntent` for Spotlight/Siri discovery)
   does not carry the `@_alwaysEmitConformanceMetadata` attribute that `AppIntent` itself
   carries. Without that attribute, Apple's `appintentsmetadataprocessor`/
   `appintentsnltrainingprocessor` build tools cannot discover an `AppShortcutsProvider`
   conformance across a Swift package → app-target module boundary. This was empirically
   confirmed via the build output of `appintentsnltrainingprocessor` during T13 (not guessed) —
   an `AppShortcutsProvider` living in `ApinCore` silently failed to register.

Both T13 and T17 needed the same underlying guarantee the plan's bullet was actually protecting:
no duplicated ask/save logic, no drift between entry points. That guarantee was achievable via a
different mechanism than "one shared type living in one package."

## Decision

App Intents orchestration is split by real dependency/SDK boundary rather than kept entirely
in `ApinCore`: `AskApinIntent` (the `AppIntent` itself) and `AskDeepLinkCoordinator` live in
`ApinCore/Sources/AppIntents` as planned, but `AskApinShortcutsProvider` (the
`AppShortcutsProvider` conformance) and the `AskAndSaveServicing`/`AskAndSaveService`
orchestration live in the `Apin` app target. T13/T17 reach the shared ask/save flow indirectly
(deep-link → `AskView` → `AskViewModel.submit()` → `AskAndSaveServicing`) rather than a shared
`ApinCore` service calling it directly, and the widget's quick-ask button deep-links into the
app rather than invoking anything itself.

## Alternatives considered

- **Keep `AskAndSaveService` and `AskApinShortcutsProvider` in `ApinCore` as the plan literally
  states** — rejected: `AppShortcutsProvider` registration silently fails to be discovered by
  Apple's build tooling across the package → app-target boundary (verified, not assumed);
  moving `AskAndSaveService` would require pulling app-target-scoped dependencies
  (`AssistantSessionProviding`) into the shared package for no functional benefit.
- **Duplicate a thin ask/save wrapper in the app target instead of routing through the deep-link
  → view → view-model path** — rejected: would create exactly the "two entry points drift"
  risk the plan's architecture bullet was trying to prevent; the deep-link-through-UI approach
  reuses the one real implementation (`AskViewModel.submit()`) instead.

## Consequences

- Makes it easy to keep T13/T17's entry points from silently diverging (both go through the
  same `AskViewModel.submit()` code path — verified by the reviewer via `canSubmit` guard
  tracing).
- Makes it harder to add an inline (no-app-open) Siri/Spotlight answer later (a T15-style
  feature): `AskAndSaveService`'s header already flags that such work would need to relocate
  the orchestration into `ApinCore` (or otherwise make it reachable without the app UI) before
  an `AppIntent.perform()` could call it directly.
- Any future App Intents work should verify the `AppShortcutsProvider` /
  `@_alwaysEmitConformanceMetadata` constraint against the current SDK before assuming a
  cross-module registration will work — this is an SDK behavior, not a project choice, and may
  change in future Apple toolchains, but should be re-verified rather than assumed fixed.
- `planning/engineering-plan.md`'s architecture bullet ("App Intents and widget code live in the
  shared `ApinCore` package") is now stale relative to the as-built system; future `/plan` runs
  should treat this ADR, not that bullet, as the current source of truth for where App Intents
  code lives.
