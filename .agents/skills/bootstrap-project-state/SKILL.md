---
name: bootstrap-project-state
description: Fill or refresh AGENTS.md, docs/project/current_state.md, and docs/project/critical_path.md from repository evidence without inventing facts. Use when a repo has thin state templates or stale restart docs and Codex should reconstruct the durable project summary from local files.
---

Use this skill to bootstrap the repository's thin constitution and durable project-state docs from checked-in evidence.

This skill is for initialization or refresh, not for broad architecture redesign.

## Inputs

Provide:
- target files
- optional local paths that are likely sources of truth
- optional non-goals
- optional date cutoff or recency focus

Default target files:

- `AGENTS.md`
- `docs/project/current_state.md`
- `docs/project/critical_path.md`

## Workflow

1. Inspect the target files first to see what is missing or stale.
2. Build a compact evidence set from the smallest relevant local artifacts.
   - Prefer checked-in docs, config, task boards, contracts, and recent repo history.
   - Use `swarm-research-pack` when the source set is broad.
3. Separate:
   - confirmed facts
   - explicit assumptions
   - missing information
4. Fill `AGENTS.md` only with stable, durable information.
   - Keep it thin.
   - Move detail into the project docs instead of bloating `AGENTS.md`.
5. Fill `docs/project/current_state.md` with:
   - project snapshot
   - stable decisions
   - active work
   - recent accepted changes
   - open risks
6. Fill `docs/project/critical_path.md` with:
   - current goal
   - active dependency chain
   - known blockers
   - recent path changes only if evidenced
7. If a required fact is missing, mark it as unknown instead of inventing a value.
8. Write back the minimum edits needed to make the templates usable.

## Evidence Priority

Prefer evidence in this order:

1. target docs already in the repo
2. checked-in project docs and contracts
3. task board or execution-plan docs
4. code and config that reveal active architecture
5. recent git history when it clarifies accepted changes

Do not treat casual chat claims as durable truth unless they were written into the repo.

## Guardrails

- Do not fabricate task IDs, blockers, or roadmap items.
- Keep `AGENTS.md` as a constitution, not a state ledger.
- Keep `current_state.md` compressed.
- Keep `critical_path.md` to the active chain only.
- Quote uncertainty explicitly.
- If the repo lacks enough evidence, stop with a short missing-info list instead of guessing.

## Output Contract

Use this section order unless the user asks for something else:

```markdown
# Project State Bootstrap
## Evidence Set
## Filled AGENTS Summary
## Filled Current State
## Filled Critical Path
## Unknowns And Assumptions
## Write-Back Targets
```

## Resources

- `references/doc-scopes.md`: what belongs in each target file.
- `references/evidence-checklist.md`: where to look first and what to avoid.
- `swarm-research-pack`: use when the evidence set is broad.
- `task-writeback`: use when the drafting phase is done and only durable write-back remains.
