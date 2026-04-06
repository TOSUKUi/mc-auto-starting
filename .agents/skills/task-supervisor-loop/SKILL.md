---
name: task-supervisor-loop
description: Coordinate a task through task-scoped research, implementation, evaluation, and write-back phases so live context stays small. Use when Codex should avoid one long session and instead pass compact artifacts between phases or subagents.
---

Use this skill to run a bounded supervisor loop around a task without letting restart docs, project history, and implementation detail accumulate in one prompt.

## Inputs

Provide:
- task id or short label
- goal
- done definition
- optional constraints, local paths, non-goals, and write-back targets

If the task spans many docs or files, prepare a pack first with `swarm-research-pack`.

## Workflow

1. Normalize the task into a short `task_record` with:
   - `task_id`
   - `goal`
   - `constraints`
   - `done_definition`
   - `non_goals`
   - `write_back_targets`
2. Decide whether to build a `research_pack`.
   - Use `swarm-research-pack` when the task touches multiple docs, multiple code areas, or ambiguous requirements.
   - Skip the extra phase only when the needed context is already narrow and obvious.
3. Produce an `implementation_brief` from the task record and research pack.
4. Hand the implementation brief to `task-implementer`.
5. Hand the implementation result to `task-evaluator`.
6. If accepted, hand the evaluation result to `task-writeback`.
7. Keep only the active phase summary and artifact pointers in live context. Do not keep raw phase transcripts resident.

## Artifact Rules

Use these artifacts and keep each one short.

- `task_record`
  - durable task framing
- `research_pack`
  - selected evidence for this task only
- `implementation_brief`
  - scope, invariants, files in scope, checks to run
- `evaluation_report`
  - pass or fail, findings, residual risks, doc mismatches
- `restart_note`
  - latest outcome, next action, reload set
- `plan_delta`
  - optional, only when dependency order or critical path changes

## Guardrails

- Prefer fresh sessions for research, implementation, evaluation, and write-back.
- Pass structured artifacts, not raw transcripts.
- Expand context only when blocked, then record why the expansion was needed.
- Keep `AGENTS.md` thin. Do not turn it back into a state ledger.
- Prefer re-derivation from task metadata, diffs, docs, and adjacency over hand-maintained task-specific summaries.
- Spawn subagents only when the user explicitly wants delegation or the task has independent sidecar work.

## Output Contract

Use this section order unless the user asks for something else:

```markdown
# Task Loop
## Task Record
## Research Decision
## Implementation Brief
## Evaluation Gate
## Write-Back Targets
## Next Boundary
```

## Resources

- `references/artifact-contracts.md`: compact schemas for the handoff artifacts.
- `references/session-boundaries.md`: what each phase may read, write, and pass forward.
- `swarm-research-pack`: preferred evidence-pack step before implementation when the task is broad.
- `task-implementer`: implementation phase skill.
- `task-evaluator`: evaluation phase skill.
- `task-writeback`: restart-doc and plan-delta phase skill.
