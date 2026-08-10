# Spec / PRD — <feature or cycle name>

This is the source of truth for this cycle. `/plan` reads only this file (plus `memory/`) to
produce the engineering plan — if it's not written down here, assume the planner doesn't know it.

Copy this file to `planning/spec.md` (or `planning/spec-<name>.md` if running multiple specs)
and fill it in before running `/plan`.

## Problem

What's broken or missing, for whom, and why it matters now.

## Goals

What success looks like. Specific and checkable, not aspirational.

## Non-goals

What's explicitly out of scope for this cycle, to stop scope creep during planning.

## Users / use cases

Who this is for and the concrete scenarios it needs to handle.

## Requirements

Numbered, testable requirements. Mark each as Must / Should / Nice-to-have.

1. Must — ...
2. Should — ...

## Constraints

Technical, timeline, or resource constraints the plan must respect.

## Open questions

Anything unresolved that the planner should flag rather than guess at.
