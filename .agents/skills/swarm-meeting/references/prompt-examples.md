# Prompt Examples

Use these as short invocation patterns for `swarm-meeting`.

## Minimal

```text
Use the swarm-meeting skill.
Topic: Design a Granary-centered task-scoped context retrieval system.
```

Expected default behavior:
- profile defaults to `balanced`
- need defaults to `options, objections, and recommendation`

## Balanced Review

```text
Use the swarm-meeting skill.
Profile: balanced
Topic: Design a Granary-centered task-scoped context retrieval system.
Need: practical architecture options, objections, and an MVP recommendation.
Constraints:
- Minimize manual per-task context contracts.
- Keep the system incrementally adoptable.
```

## Stronger Architecture Pressure

```text
Use the swarm-meeting skill.
Profile: architecture-debate
Topic: Decide how Tree-sitter, import adjacency, and optional LSP should interact in context retrieval.
Need: boundary design, failure modes, and a phased implementation plan.
Artifacts:
- docs/context-retrieval.md
- src/indexer/
- src/retrieval/
```

## High-Conflict Decision Meeting

```text
Use the swarm-meeting skill.
Profile: extreme-diversity
Topic: Decide whether to favor fresh task-scoped sessions over long-lived sessions with pruning.
Need: hard tradeoffs, objections, and one opinionated recommendation.
```

## Fast MVP Pass

```text
Use the swarm-meeting skill.
Profile: balanced
Topic: Choose the MVP for task-scoped context retrieval.
Need: what can ship in 1-2 weeks.
Bias: favor simplicity and operator control.
```

## Meeting After Research Pack

```text
Use the swarm-research-pack skill first to prepare a pack.
Topic: Prepare evidence for a retrieval-architecture decision.
Paths:
- docs/
- src/retrieval/
- src/context/

Then use the swarm-meeting skill.
Profile: architecture-debate
Topic: Decide the retrieval architecture using the prepared pack.
Need: recommendation, open questions, and next actions.
```

## Vague Natural Request

```text
この件を swarm-meeting で軽くレビューして。MVP寄りで。
```

Preferred behavior:
- infer `balanced`
- infer a short topic from conversation context
- keep the assist block short before continuing
