# 004. Foundation Models' guided generation supports incremental partial-`@Generable` streaming

Status: Accepted
Date: 2026-08-12
Sprint: Sprint 5 (see memory/sprint-summary.md)

## Context

Cycle 5's plan (`planning/engineering-plan.md` v1.4) needed a structured-output shape for Apin's
answer + follow-up question + suggested chips + topic tags (`AskResponse`), replacing/extending
the plain-`String` model-call surface. The plan explicitly flagged an open risk: it was not known,
without live-checking current Apple documentation, whether Foundation Models' streaming API
(`LanguageModelSession.streamResponse(to:generating:)`) supports incremental partial snapshots of
a `@Generable` type the way `streamResponse(to:)` streams cumulative partial strings — this matters
because the design handoff's Ask screen requires token-by-token streaming with a live typing
indicator, and a deferred future task (Stage B item 9) will need to stream a *structured* response,
not just plain text, to render the follow-up/chips/tags progressively rather than only after the
full structured response completes.

T2 (Cycle 5) investigated this directly rather than guessing, against two independent real
sources on the implementing machine (not training-data recall): Apple's own bundled
`FoundationModels-Using-on-device-LLM-in-your-app.md` doc inside the installed Xcode 26.6, and the
real `FoundationModels.framework`'s `.swiftinterface`, cross-checked via a throwaway SPM scratch
package that was built against the real framework and then deleted. Macro expansions were dumped
(`-Xfrontend -dump-macro-expansions`) to inspect the actual generated code, not just the public
interface surface.

## Decision

`LanguageModelSession.streamResponse<Content>(to:generating:includeSchemaInPrompt:options:) ->
ResponseStream<Content>` **does exist and does support** incremental structured streaming: it
yields `Snapshot { content: Content.PartiallyGenerated, rawContent: GeneratedContent }`, where
`PartiallyGenerated` is a macro-synthesized mirror struct with every property optional (confirmed
directly in the dumped macro expansion for `AskResponse`, not assumed from the doc alone). This
resolves the plan's previously-open risk as a confirmed fact, not a remaining unknown: a future
task building a streaming structured-response UI (deferred Stage B item 9) can stream `AskResponse`
directly via this API, rather than needing the plan's documented fallback (stream the answer as
plain text today, then a separate short structured call afterward for
`followUpQuestion`/`chips`/`tags` once the answer finishes).

T2 itself did not add a structured-streaming method — only the non-streamed
`sendStructured(prompt:) async -> Result<AskResponse, AssistantResponseError>` entry point, since
consuming structured output in the UI is out of Cycle 5 Stage A's scope. This ADR records the
*capability* as verified, not an implementation of it.

## Alternatives considered

- **Assume unsupported, plan for the two-call fallback from the start** — rejected: the plan
  explicitly asked this to be verified during implementation rather than assumed either way, since
  guessing wrong in either direction has cost (assuming unsupported when it's supported means a
  future task reimplements a worse two-call UX unnecessarily; assuming supported when it isn't
  means a future task discovers the gap mid-implementation with no fallback ready). T2 did the
  actual verification instead of picking a default.
- **Trust the doc's prose description alone** — rejected: the doc describes the streaming API's
  existence and shape, but confirming that `PartiallyGenerated`'s macro-synthesized shape actually
  supports a real `AskResponse` conformance (all-optional mirror struct compiles and streams)
  required dumping the actual macro expansion against this project's own `@Generable` type, not
  just reading Apple's prose.

## Consequences

- Deferred Stage B item 9 (structured streaming UI for the Ask screen's follow-up chips/message
  history) now has a confirmed, verified implementation path — `streamResponse<AskResponse>` —
  rather than an open question to re-investigate from scratch next cycle.
- The plan's documented two-call fallback (stream text now, structured call after) is not needed
  and should not be implemented by default when Stage B item 9 is picked up — using the confirmed
  single-call structured-streaming path is the correct default going forward, unless a future
  cycle's implementation surfaces a concrete reason (e.g. a performance regression) to prefer the
  fallback instead.
- This is a fact about the Foundation Models framework itself (SDK-version-dependent, per ADR 001's
  own "Consequences" section precedent for this kind of framework-behavior fact) — worth
  re-verifying if a future cycle's SDK/toolchain version changes materially, same discipline this
  project already applies to the iOS-floor re-checks, rather than assumed permanently stable.
