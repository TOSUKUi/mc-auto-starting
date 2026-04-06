# Legacy Design Review Prompt

This reference preserves the original one-off meeting prompt that seeded the reusable `swarm-meeting` skill.

Use it when the meeting topic is specifically about task-scoped context retrieval, Granary, session reset strategy, and Codex subagents.

## Original Brief

You are facilitating a design review meeting for a developer tooling project.

Goal:
We want to design a system that prevents irrelevant context from accumulating in long-lived coding-agent CLI sessions.
The target outcome is a practical architecture for:
1. selecting only task-relevant documents/code context,
2. discarding irrelevant accumulated context,
3. starting fresh task-scoped sessions for coding agents,
4. supporting handoff/checkpoint/history without polluting the live session.

Important background:
- We are interested in Granary as a task/context hub.
- We are also interested in a separate retrieval/context agent that can infer needed context from:
  - task metadata
  - touched files / git diff
  - grep / ripgrep
  - Tree-sitter symbol structure
  - import/call/test/config adjacency
  - optional LSP/compiler semantics later
- We do NOT want a design that requires manually maintaining detailed per-task context contracts, because that becomes tedious and stale.
- We prefer a design where task metadata is minimal, and task context is mostly re-derived.
- We want to consider Codex subagents as part of the solution design process.

Meeting objectives:
- Clarify the problem precisely.
- Enumerate 3-5 realistic architecture options.
- Compare them rigorously.
- Identify the best MVP path.
- Identify what should be human-maintained vs inferred automatically.
- Identify where Granary fits and where a custom retrieval layer is still needed.
- Identify whether Tree-sitter alone is enough, and where LSP/compiler assistance becomes necessary.
- Produce a concrete next-step implementation plan.

Constraints:
- Be explicit about assumptions.
- Prefer practical, incrementally adoptable solutions.
- Avoid over-abstract architectures that cannot be implemented soon.
- Treat manual per-task context contract maintenance as a major cost to minimize.
- Distinguish clearly between:
  - task system / orchestration
  - context retrieval / selection
  - live-session pruning / reset strategy
  - history / handoff storage
- When discussing tools, separate what existing tools can do today vs what would need custom implementation.

Required deliverable format:

```markdown
# Design Review
## Problem Statement
## Agenda
## Role Memos
## Options Considered
## Recommended Architecture
## MVP Plan
## Risks and Failure Modes
## Open Questions
## Concrete Next Actions
```
