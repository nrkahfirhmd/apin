# Architecture Decision Records

One file per decision: `adrs/00N-short-title.md`. Numbered sequentially, never renumbered or
deleted — superseded decisions stay, marked as such.

## Template

```markdown
# 00N. <Decision title>

Status: Proposed | Accepted | Superseded by 00X
Date: YYYY-MM-DD
Sprint: <sprint summary link>

## Context
What problem forced this decision. What constraints applied.

## Decision
What was decided, stated as a single clear sentence.

## Alternatives considered
- Option A — why rejected
- Option B — why rejected

## Consequences
What this makes easier, what it makes harder, what debt (if any) it creates.
```

The `memory-keeper` subagent creates a new file here whenever `/review` or `/remember`
surfaces a decision with lasting architectural impact.
