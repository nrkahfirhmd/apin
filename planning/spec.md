# Spec / PRD — Apin (Personality AI Assistant + Studying Journal)

This is the source of truth for this cycle. `/plan` reads only this file (plus `memory/`) to
produce the engineering plan.

## Problem

There's no offline, privacy-preserving assistant that both answers the random questions someone
has throughout the day *and* keeps a running record of what they learned. General-purpose
assistants (Siri, ChatGPT apps) either require network access, have no persistent personality,
or don't turn everyday curiosity into something reviewable later. Kv wants a single companion,
"Apin," that lives on-device, answers in its own voice, and quietly builds a studying journal out
of every question asked.

## Goals

1. Apin answers general/random questions fully offline, using Apple's on-device Foundation
   Models framework (Apple Intelligence) as the base model — no network call required to get an answer.
2. Apin has a consistent, recognizable personality (name, tone, voice) applied to every answer.
3. Every question + answer is automatically captured as an entry in a persistent studying journal,
   browsable and searchable later.
4. Apin is reachable in under a few seconds from where the user already is: iOS Spotlight search
   and a home screen widget.
5. Journal data is stored in a way that isn't locked to this app, so a Mac companion can read it
   in a later cycle.

## Non-goals (this cycle)

- Mac app or Mac command-line access — deferred to a follow-up cycle.
- Cloud/hybrid model fallback — on-device only for now.
- Multi-user, sharing, or social/collaborative features.
- Dedicated iPad layout (app should run on iPad via iOS compatibility, but no custom iPad UI work).
- Voice-first / Siri spoken interaction (typed Spotlight query is in scope; full Siri conversation is not).

## Users / use cases

Primary user: Kv — a curious person who has random questions throughout the day and wants a
lightweight, private way to get an answer and keep a trace of what they learned.

- Walking somewhere, wonders "why is the sky red at sunset" — opens Spotlight, types "Apin
  [question]" or opens Apin directly, gets an answer, it's saved to the journal automatically.
- Glances at the home screen widget, taps a quick-ask entry point to fire off a question without
  fully opening the app.
- No signal (flight, subway, poor connection) — Apin still answers, since everything runs
  on-device.
- End of week, opens the journal to skim back through what they asked and learned.

## Requirements

1. Must — Apin answers questions fully offline using Apple's on-device Foundation Models
   framework; no network request is made to produce an answer.
2. Must — Apin has a defined personality (name "Apin," consistent tone/voice) applied via
   system instructions to every model call.
3. Must — Every question + answer pair is automatically saved as a journal entry in on-device
   persistent storage.
4. Must — Journal entries are browsable and searchable in-app (by date and keyword).
5. Must — Apin is invocable from iOS Spotlight search (via App Intents / Siri & Shortcuts
   integration), letting the user ask a question or jump into the app.
6. Must — Apin ships a home screen widget for quick access (quick-ask entry point and/or most
   recent journal entry).
7. Must — Graceful, clear handling on devices/OS versions that don't support Apple Intelligence's
   on-device Foundation Models (rather than a silent failure).
8. Should — Journal entries are also written in a portable format (e.g., Markdown or JSON) in
   addition to the native store, so a later Mac companion can read the same data.
9. Should — Journal syncs via iCloud so it isn't stranded on a single device.
10. Nice-to-have — Tagging/categorizing journal entries by topic.
11. Nice-to-have — Weekly digest or "streak" view of learning activity.

## Constraints

- Requires Apple Intelligence–capable hardware and an iOS version that supports the on-device
  Foundation Models framework. Exact minimum device/OS version needs to be verified against
  current Apple developer documentation during planning — this shifts as Apple updates
  requirements.
- Solo developer (Kv), no backend/server component — everything must work standalone on-device.
- Swift/SwiftUI native iOS app implied by the on-device model requirement and widget/Spotlight
  integration.
- No specific deadline set yet.

## Open questions

- Minimum supported iPhone model and iOS version for the Foundation Models framework — needs
  verification against current Apple docs before implementation starts.
- Personality brief for "Apin": is the name short for something, and is there a specific
  tone/character reference (playful, deadpan, encyclopedic, etc.) beyond "has personality"?
- Exact Spotlight behavior: Siri/Shortcuts App Intent that answers inline, deep link into the
  app, indexed journal entries appearing as search results — or some combination?
- Any automatic retention/archiving of journal entries, or fully manual/forever by default?
- Answer language — English only, or should Apin also respond in Indonesian?
